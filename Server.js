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
    callback(null, './uploads');
  },
  filename: function (req, file, callback) {
    callback(null, file.fieldname  + Date.now() + ".xlsx"); //this is for applying a unique name to uploads, might be necessary to handle parallel requests
  }
});

var upload = multer({ storage : storage}).single('userParameters');
var params = multer();

app.get('/',function(req,res){
        req.socket.setTimeout(10 * 60 * 1000);
      res.sendFile(__dirname + "/index.html");
});

app.get('/WebForm',function(req,res){
        req.socket.setTimeout(10 * 60 * 1000);
      res.sendFile(__dirname + "/WebformUpload.html");
});

app.get('/WorkbookUpload',function(req,res){
        req.socket.setTimeout(10 * 60 * 1000);
      res.sendFile(__dirname + "/WorkbookUpload.html");
});

app.get('/License',function(req,res){
        req.socket.setTimeout(10 * 60 * 1000);
      res.sendFile(__dirname + "/License.html");
});

app.use(express.static('images'));

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
        var outputFile = __dirname + "/uploads/" + outputName;
        var child = spawn("matlab",["-nodisplay", "-nosplash", "-nodesktop", "-logfile", outputFile, "-r", "cd matlabOverhangFinder; userSpreadsheet = '" + "../uploads/" + req.file.filename + "'; Experimental_Driver_Jan2017(userSpreadsheet); exit;"],{}); //this call is really stupid; it probably belongs in a .bat or something
        
        child.on('error', function(err) {
          console.log('Spawn Matlab Job failed ' + err);
        });
        
        fs.watchFile(outputFile, (curr, prev) => {//watch for file updates
            readLastLines.read(outputFile, 4).then(function(lines) { //check last lines
                if (lines.indexOf("Script completed!") > -1) { // success
                    fs.readFile(outputFile, 'utf8' , (err, data) => {
                      if (err) {
                        console.log(err);
                        return res.end("Error running Matlab");
                    }
                      console.log("Completed upload Job: " + req.file.filename);
                      return res.end(data);
                    });
                } else if (lines.toLowerCase().indexOf("error") > -1) { //failure
                            fs.readFile(outputFile, 'utf8' , (err, data) => {
                              if (err) {
                                console.log(err);
                                return res.end("Error running Matlab");
                            }
                              console.log("Upload job: " + req.file.filename + " erred");
                              return res.end(data);
                            });
                        }
            }).catch(function(err) {console.log("ReadLines Error: " + err); return res.end("Failed to read upload: " + err + "?");} );
    });

    setTimeout(function() {
        fs.unlinkSync("./uploads/" + req.file.filename, function(err){
            if(err) {
                console.log(err);
                return res.end("5 minute job time-out reached");
            }
        }); 
    }, 5*60*1000);
    
  });
});


app.post('/webform', uploadLimiter , params.array(), function (req, res, next) {
    
    var workBookName = "Accompanying Excel Workbook.xlsx";
    var sheetName = 'Example';
    var uniqueTime = Date.now();
    var filename = "Websheet" + uniqueTime + ".xlsx";
    var outputName = "Output" + uniqueTime + ".txt";
    var outputFile = __dirname + "/uploads/" + outputName;
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
    sheet1.getCell('H12').value = parseInt(data.RepeatLength);
    
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

    
    workbook.xlsx.writeFile("./uploads/" + filename)
        .then(function() {
            spawn("matlab",["-nodisplay", "-nosplash", "-nodesktop", "-logfile", outputFile, "-r", "cd matlabOverhangFinder; userSpreadsheet = '" + "../uploads/" + filename + "'; Experimental_Driver_Jan2017(userSpreadsheet); exit;"],{});
        });

        fs.watchFile(outputFile, function (curr, prev) {
                    // console.log(prev);
                    readLastLines.read(outputFile, 4).then(function(lines) {
                        // console.log(lines);
                        if (lines.indexOf("Script completed!") > -1) {
                            fs.readFile(outputFile, 'utf8' , (err, data) => {
                              if (err) {
                                console.log(err);
                                return res.end("Error running Matlab");
                            }
                            return res.end(data);
                            });
                        } else if (lines.toLowerCase().indexOf("error") > -1) {
                            fs.readFile(outputFile, 'utf8' , (err, data) => {
                              if (err) {
                                console.log(err);
                                return res.end("Error running Matlab");
                            }
                            return res.end(data);
                            });
                        }
                    }).catch(function(err) {console.log("ReadLines Error: " + err);  return res.end("Failed to interpret uploaded parameters");} ); //not able to read the output file that matlab made earlier
                });
                
               
        setTimeout(function() {
            fs.unlinkSync("./uploads/" + filename, function(err){
                if(err) {
                    console.log(err);
                }
            }); 
        }, 5*60*1000);

    });

app.get('/workbook',function(req,res){
    req.socket.setTimeout(10 * 60 * 10000);
    res.sendFile(__dirname + "/workbook.xlsx");
});

app.listen(80,function(){
    console.log("Working on port 80");
});