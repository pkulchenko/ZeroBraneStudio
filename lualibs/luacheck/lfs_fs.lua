local lfs = require "lfs"

local lfs_fs = {}

function lfs_fs.get_mode(path)
   return lfs.attributes(path, "mode")
end

function lfs_fs.get_current_dir()
   return assert(lfs.currentdir())
end

function lfs_fs.get_mtime(path)
   return lfs.attributes(path, "modification")
end

function lfs_fs.dir_iter(path)
   return lfs.dir(path)
end

return lfs_fs
