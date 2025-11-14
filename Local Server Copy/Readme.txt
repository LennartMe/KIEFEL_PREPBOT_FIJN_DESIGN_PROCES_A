Below Folder is a copy of the Python local server located on the C drive of the Production VM of Kiefel.

This server is for retrieving the files on the file server and having them accessible with an http link.

This is a work arround for the uipath limitation of only opening http and https links from within an app.

In the serve_S_drive.py file, there is a function to add a PC name so it will also be able to access the files.