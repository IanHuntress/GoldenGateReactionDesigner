# GoldenGate Reaction Designer Website
The site accepts user parameters for the GG reaction, enters them into exel format located in /uploads, runs the overhangFinder matlab script and returns the results to the user.

* Dependencies: express,  multer, readLastLines, exceljs, express-rate-limit, Matlab

* The server should be launched by running "node Server.js" from the main directory (default port 80)

* To launch server on startup, use /etc/init.d