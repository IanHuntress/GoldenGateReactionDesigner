# GoldenGate Reaction Designer Website
The site accepts user parameters for the GG reaction, enters them into exel format located in /uploads, runs the overhangFinder matlab script and returns the results to the user.

* Dependencies: express,  multer, readLastLines, exceljs, express-rate-limit, Matlab

* Images for thumbnails/help links are hosted from the images folder.

* The file named workbook.xlsx in the main directory is what user downloads from the "Workbook Upload" page.

* The server should be launched by running "node Server.js" from the main directory (default port 80)

* To launch server on startup, use /etc/init.d