# H1 GoldenGate Reaction Designer Website
The site accepts user parameters for the GG reaction, enters them into exel format located in /uploads, runs the overhangFinder matlab script and returns the results to the user.

1. Images for thumbnails/help links are hosted from the images folder.

2. The file named workbook.xlsx in the main directory is what user downloads from the "Workbook Upload" page.

3. There may be problems with matlab jobs not properly terminating with broken inputs.

4. There are probably problems with unsanitized user input.

5. The server should be launched by running "node Server.js" from the main directory (currently on port 80)

6. The navigation bar appears to change size sometimes. It should be included from a separate page, rather than copied over on every page.


Notes?
If the matlab code errors because of bad inputs, what should the user see?
There might be problems with paths between windows and linux, forward/backward slashes?
There are basically no protections against crashing the site with a flood of requests (I am not a CS Security major)
