class Project
  path: null
  rootPath: null
  fullPath: @path + @rootPath

  getName: () ->
    @path.match(/\w+$/ig)[0]

  http: null
  listText: null
  files: null
