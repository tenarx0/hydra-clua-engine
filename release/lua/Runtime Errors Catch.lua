function onHydraError(err)
    -- catches runtime errors and logs them to logcat, use your own logging system if you have one.
    logcat.error(err);
end