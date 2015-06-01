==Azure Web apps tricks

To be able to modify applicationHost.config, put applicationHost.xdt to sites folder (it is parent to wwwroot, where web app is residing) and restart web app.
Modification will be logged in logger