var express =   require("express");
var multer  =   require('multer');
var app         =   express();
var spawn = require('child_process').spawn;
var fs      =   require("fs");
const readLastLines = require('read-last-lines'); // published by alexbbt under MIT license
var Excel = require('exceljs'); // published by Guyon Roche under MIT license
var path = require('path');
var RateLimit = require("express-rate-limit"); //nfriedly published under MIT license

var storage =   multer.diskStorage({
  destination: function (req, file, callback) {
    callback(null, path.join(__dirname,"uploads"));
  },
  filename: function (req, file, callback) {
    callback(null, file.fieldname  + Date.now() + ".xlsx"); //this is for applying a unique name to uploads, might be necessary to handle parallel requests
  }
});

var upload = multer({ storage : storage}).single('userParameters');
var params = multer();

app.use('/', express.static(path.join(__dirname, 'site')));
app.use(express.static(path.join(__dirname, 'images')));

var uploadLimiter = new RateLimit({
  windowMs: 5*60*1000, // 5 mins
  delayAfter: 1, // begin slowing down responses after the first request 
  delayMs: 3*1000, // slow down subsequent responses by 3 seconds per request 
  max: 3, // start blocking after 5 requests 
  message: "Too many job requests created from this IP, please try again in 5 minutes"
});

app.post('/useruploads', uploadLimiter ,function(req,res) {
    userFile = upload(req,res,function(err) {
        if(err) {
            console.log(err);
            return res.end("Error uploading file.");
        }
        req.socket.setTimeout(10 * 60 * 1000);
        var uniqueTime = Date.now();
        var outputName = "Output" + uniqueTime + ".txt";
        var outputFile = path.join(__dirname,"uploads",outputName);
        if(req.file){
            var fName = req.file.filename;//this might be a terrible vulnerability
        }
        // var child = spawn("matlab",["-nodisplay", "-nosplash", "-nodesktop", "-logfile", outputFile, "-r", "cd matlabOverhangFinder; userSpreadsheet = '" + "../uploads/" + fName + "'; Experimental_Driver_Jan2017(userSpreadsheet); exit;"],{});  //this works only on windows because paths
        var child = spawn("matlab",["-nodisplay", "-nosplash", "-nodesktop", "-logfile", outputFile, "-r", "cd matlabOverhangFinder; userSpreadsheet = '" + path.join(__dirname,"uploads",fName) + "'; Experimental_Driver_Jan2017(userSpreadsheet); exit;"],{}); 
        
        child.on('error', function(err) {
          console.log('Spawn Matlab Job failed ' + err);
        });
        
        var watcher = fs.watchFile(outputFile, (curr, prev) => {//watch for file updates
            readLastLines.read(outputFile, 4).then(function(lines) { //check last lines
                if (lines.indexOf("Script completed!") > -1) { // success
                    fs.readFile(outputFile, 'utf8' , (err, data) => {
                      if (err) {
                        console.log(err);
                        return res.end("Error running Matlab");
                        watcher.close();
                    }
                      console.log("Completed upload Job: " + fName);
                      return res.end(data);
                      watcher.close();
                    });
                } else if (lines.toLowerCase().indexOf("error") > -1) { //failure
                            fs.readFile(outputFile, 'utf8' , (err, data) => {
                              if (err) {
                                console.log(err);
                                return res.end("Error running Matlab");
                                watcher.close();
                            }
                              console.log("Upload job: " + fName + " erred");
                              return res.end(data);
                              watcher.close();
                            });
                        }
                        
                        
                setTimeout(function() {
                    try {
                    fs.unlinkSync(path.join(__dirname,"uploads",fName), function(err){
                        if(err) {
                            console.log(err);
                        } else {
                            return res.end("8 minute job time-out reached");
                        }
                    }); 
                    }
                    catch(err) {
                        console.log("Error destroying old user upload: " + err);
                    }
                }, 8*60*1000); //this sets the timeout
    
            }).catch(function(err) {console.log("ReadLines Error: " + err);} ); //this catch is not really a problem even though sometimes fs.watch fires when there is nothing to read
    });                                                                         //We might generate huge log files in /var/log/node (eventually)

  });
});


app.post('/webform', uploadLimiter , params.array(), function (req, res, next) {
    
    var workBookName = "Accompanying Excel Workbook.xlsx";
    var sheetName = 'Example';
    var uniqueTime = Date.now();
    var filename = "Websheet" + uniqueTime + ".xlsx";
    var outputName = "Output" + uniqueTime + ".txt";
    var outputFile = path.join(__dirname,"uploads",outputName);
    var data = req.body;
    
    var workbook = new Excel.Workbook(); //this excel module cannot write onto existing sheets, always make a new one. <sadFace>
    var sheet1 = workbook.addWorksheet('Example');
    
    // console.log(data); //data is the object containing all webform user input

    //Load the webform data into the XL sheet, so we can feed it to the matlab script later
    sheet1.getCell('D2').value = "Necessary Inputs";
    sheet1.getCell('D4').value = "Sequence of DNA composing a <Repeat>[Dropout]<Repeat> in the 5'->3' direction:";
    
    if(data.Repeatdropoutrepeat){
    sheet1.getCell('D5').value = data.Repeatdropoutrepeat; //TODO: write a sanitize_inputs function for security
    }
    
    sheet1.mergeCells('D5', 'I5'); //this line is innocuous but important, Matlab xl reader relies on this
    
    // Section A
    sheet1.getCell('H7').value = "Natural sequence of the repeat region in the 5'->3' direction:";
    
    if(data.Repeattocheck){
        sheet1.getCell('H7').value = data.Repeattocheck;
    }
    
    // Section B
    sheet1.getCell('D9').value = "Number of CRISPR spacers in the final array:";
    sheet1.getCell('H9').value = parseInt(data.Spacernum);
    
    // Section C
    sheet1.getCell('H11').value = parseInt(data.Spacerlength);
    sheet1.getCell('H12').value = parseInt(data.Minmismatchnum);
    
    // Section D
    if(data.Desiredenz){
        sheet1.getCell('H14').value = data.Desiredenz; //sanitize_inputs
    }
    // Section E
    if(data.Desiredseq_bin == "Yes"){
        sheet1.getCell('H16').value = 1;
        
        var singleAxisMatrix = data.ArrayChoice.split(/[\r\n\t ,]+/);
        
        for (var i = 0; i< singleAxisMatrix.length; i++){
            sheet1.getCell('E' + parseInt(32 + i)).value = singleAxisMatrix[i];
        }
    } else {
        sheet1.getCell('H16').value = 2;
    }
    
    // Section F
    var maxSpacerOptions = 14;
    var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    if(data.Desiredspacerorder_bin == "Yes"){
        sheet1.getCell('H19').value = 1;
        for (var i = 0; i < data.Spacernum; i++){
            for (var j = 0; j < maxSpacerOptions; j++){
                sheet1.getCell(letters[i+4] + parseInt(52 + j)).value = data["Desiredspacerorder_matrix_"+ j + "_" + i];
            }
        }
    } else {
        sheet1.getCell('H19').value = 2;
    }
    
    // Section G
    if(data.Orderoligos_bin == "Oligos"){ //naming convention sucks because 1||2 from matlab turns into string here and on webform, oops
        sheet1.getCell('H23').value = 1;
    } else if (data.Orderoligos_bin == "PCRPrimers"){
        sheet1.getCell('H23').value = 2;   
        sheet1.getCell('J69').value = parseInt(data.Orderoligos_text);
    }
    
    // Section H
    if (data.Naming_bin == "Yes") {
        sheet1.getCell('H26').value = 1;  
        sheet1.getCell('J71').value = data.Naming_text;
    } else {
        sheet1.getCell('H26').value = 2;  
    }

    console.log(path.join(__dirname,"uploads",filename));
    workbook.xlsx.writeFile(path.join(__dirname,"uploads",filename))
        .then(function() {
            spawn("matlab",["-nodisplay", "-nosplash", "-nodesktop", "-logfile", outputFile, "-r", "cd matlabOverhangFinder; userSpreadsheet = '" + path.join(__dirname,"uploads",filename) + "'; Experimental_Driver_Jan2017(userSpreadsheet); exit;"],{});
        });

        var watcher = fs.watchFile(outputFile, function (curr, prev) {
                    // console.log(prev);
                    readLastLines.read(outputFile, 4).then(function(lines) {
                        // console.log(lines);
                        if (lines.indexOf("Script completed!") > -1) {
                            fs.readFile(outputFile, 'utf8' , (err, data) => {
                              if (err) {
                                console.log(err);
                                return res.end("Error running Matlab");
                                watcher.close();
                            }
                            return res.end(data);
                            watcher.close();
                            });
                        } else if (lines.toLowerCase().indexOf("error") > -1) {
                            fs.readFile(outputFile, 'utf8' , (err, data) => {
                              if (err) {
                                console.log(err);
                                return res.end("Error running Matlab");
                                watcher.close();
                            }
                            return res.end(data);
                            watcher.close();
                            });
                        }
                    }).catch(function(err) {console.log("ReadLines Error: " + err);} ); //not able to read the output file that matlab made earlier
                });
                
                setTimeout(function() {
                    try {
                    fs.unlinkSync(path.join(__dirname,"uploads",filename), function(err){
                        if(err) {
                            console.log(err);
                        } else {
                            return res.end("8 minute job time-out reached");
                        }
                    }); 
                    }
                    catch(err) {
                        console.log("Error destroying old user upload: " + err);
                    }
                }, 8*60*1000); //this sets the timeout

    });

app.get('/workbook',function(req,res){
    req.socket.setTimeout(10 * 60 * 10000);
    res.sendFile(__dirname + "/site/workbook.xlsx");
});

app.listen(80,function(){
    console.log("Working on port 80");
});