# GoldenGate Reaction Designer Website
The site accepts user parameters for the GG reaction, enters them into exel format located in /uploads, runs the overhangFinder matlab script and returns the results to the user.

* Dependencies: express,  multer, readLastLines, exceljs, express-rate-limit, Matlab (developed for R2017a), nodejs (developed for 4.2.6)

* The server should be launched by running "node Server.js" from the main directory (default port 80)

## Renewing Matlab license:
Since we run the server without a monitor, we will use Xming to catch the Matlab display from the Linux server on our Windows machine over SSH (the important parameter is -X to enable X11)

1. Download and run Xming https://sourceforge.net/projects/xming/ (It says server because X11 has an unintuitive notion of what should be client and server)

2. Download and run putty https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html (You probably have a 64 bit system because you are reading this from the future)

3. Make sure the X11 forwarding option is enabled in putty before you connect to the server (If you can't find its IP address, either connect a monitor and run ifconfig, or find someone from the tech department to complain to)

4. Navigate to Matlab's bin directory using cd and ls. (Usually located /usr/local/MATLAB/R2017a/bin/ or sometimes /home/koffas/MATLAB/bin)

5. Run the activate_matlab.sh from the bin (Usually ubuntu runs things like this ./activate_matlab.sh)

6. Follow the Matlab prompts, usually by logging in to your mathworks account. (If the server is run at startup, for example with a crontab job (sudo crontab -u root -e), you probably want to license matlab to the root account)

7. Make sure that the right user can run Matlab (If you have done previous steps correctly and still fail, you might check the symbolic link in usr/local/bin. Use ln -s {source-filename} {symbolic-filename} to specify which version of matlab should be run when a user asks for it)

8. Profit