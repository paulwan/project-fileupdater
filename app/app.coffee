# npm  https://www.npmjs.com/package/archiver
# jetpack Api https://github.com/szwacz/fs-jetpack
archiver = require('archiver')
jetpack = require('fs-jetpack')
helper = require('./helper') # 工具函数

# 禁止 Electron App 的页面缩放[mac App]
webFrame = require('electron').webFrame
webFrame.setVisualZoomLevelLimits(1, 1)
webFrame.setLayoutZoomLevelLimits(0, 0)


# console.log jetpack.listAsync(__dirname + '/projects' )

gen = (x) ->
  y = yield x * 2
  # console.log y
  return y

g = gen(2)
# g.next()
console.log g.next()
console.log g.next(5)
console.log g.next(8)


# var Promise = require("bluebird");
# var fs = Promise.promisifyAll(require("fs"));
#
# fs.readFileAsync("./package.json", "utf8").then(function(contents) {
#     console.log(contents);
# }).catch(function(e) {
#     console.error(e.stack);
# });

console.log "#{__dirname}"

###
checkPROJ.coffee
createSTRING.coffee
appUI.coffee
dataModel.coffee


####

startWork = ->

  # App打包以后，需要重置Electron里的 '.app' 以后的路径 ,防止__dirname为Electron 的 app包内路径
  # app包内根目录路径，如果不处理是这样的: .../***.app/Contents/Resources/app.asar/app

  targetPath = __dirname.replace(/\/\w+\.app\/.+/g, '')


  # 如果没有找到project文件夹,则提出警告，并停止.
  if jetpack.exists(targetPath + '/projects') is false

    document.querySelector('#info').innerHTML = '没有找到projects文件夹 !?'
    console.log '没有找到 projects !'

    document.querySelector('#filelist').innerHTML = "<b>WARNING !</b><br>没有‘projects’文件夹? 或‘projects’文件夹是空的 ?<br>App是否在‘projects’文件夹旁?"
    return

  # 使按钮暂时无效
  document.getElementById("button").removeEventListener('click', startWork)
  document.getElementById("button").classList.add('btn-disable')
  document.querySelector('#button').innerHTML = '更新中...'

  # 将返回的cwd目录从项目所在目录指定为 app的目录 - /projects
  jetpack = jetpack.cwd(targetPath)

  # 递归删除 .DS_store
  do cleanDSStore = (targetPath) ->

    _dsStoreList = jetpack.find(targetPath, { matching: ['*.DS_Store']} )
    for __beClean in _dsStoreList
      jetpack.remove(__beClean)

    console.log 'clean .DS_store !'

  # 获取项目路径
  foldersPath = jetpack.find( targetPath + '/projects', { matching: ['*'], files: false, directories: true, recursive: false } )

  console.log 'root path is: ' + targetPath

  folders = []
  projects = []
  domFileListString = "<b> #{new Date().toLocaleDateString()} | #{new Date().toLocaleTimeString()}"
  listStrings = ''

  # 设置项目，作为对象，增加基本属性
  setupProjects = (foldersPath, folders) ->
    for path in foldersPath
      project = {}
      project.path = path
      project.rootPath = jetpack.cwd() + '/'
      project.fullPath = project.rootPath + project.path
      # 返回正则的尾部第一个单词
      project.name = path.match(/\w+$/ig)[0]
      project.http = "http://ibiart.oschina.io/standalone/#/../projects/#{project.name}/"
      project.listText = "[#{project.name}](../#{project.path}/)\n\n"
      project.files = jetpack.find( path , { matching: ['*'], files: false, directories: true, recursive: false } )
      project.updateTime = ''
      project.htmlPath = '../'
      project.isProject = true
      project.info = {}
      project.doc = {
        about_doc: [],
        spec_doc: [],
        assets_doc: [],
        preview_doc: [],
        mockdata_doc: [],
        prototype_doc: [],
        resources_doc: [],
        review_doc: [] }
      project.updateTime = new Date().toLocaleTimeString() + '  ' + new Date().toLocaleDateString()
      folders.push project
      console.log 'setup complete!'

  # 检查是否为项目类型的文件夹
  checkProjectContentExist = (folders, projects) ->

    _projectFolders = ['/about_doc','/design','/mockdata','/prototype','/resources','/review','/zip']

    for __proj in folders
      for __folder in _projectFolders
        if jetpack.exists(__proj.path + __folder) is false
          __proj.isProject = false
          # return
      if __proj.isProject is true
        projects.push(__proj)

    console.log 'checkProject complete  !'

  # 检查项目下面的为文件
  checkFile = (proj) ->
    # 仅检查md文件
    proj.doc.about_doc = jetpack.find( proj.path + '/about_doc' , { matching: ['./*.md'], recursive: false } )

    # 处理设计文件的spec，找出最新版本
    proj.info.spec_doc = jetpack.find( proj.path + '/design' , { matching: ['./*'], files: false, directories: true, recursive: false} )

    do findLatestVersion = (proj) ->
      if proj.info.spec_doc.length <= 0
        proj.doc.spec_doc = []
        proj.latestVer = '?'
      else
        _latestVersion = []
        for _verNum in proj.info.spec_doc
          # 如果找到的spec里的文件夹名尾部没有数字，就跳过
          if _verNum.search(/v\d{1,3}$/) is - 1
            return
          else
            _specName = _verNum.match(/v\d{1,3}$/ig)
            _specName = _specName[0].replace(/v/ig, "")
            _num = parseInt(_specName)
            _latestVersion.push(_num)
            _latest_VerNum = Math.max.apply(null, _latestVersion)

            if _verNum.lastIndexOf(String(_latest_VerNum)) isnt - 1
              proj.doc.spec_doc = [_verNum]

            proj.latestVer = _latest_VerNum

            # 处理 Assets
            proj.doc.assets_doc = jetpack.find( proj.doc.spec_doc[0], { matching: ['./assets'], files: false, directories: true, recursive: false} )


            # 压缩 Assets by Zip
            do assetsZip = ->
              _zipPostion = "/zip/Assets_v#{proj.latestVer}.zip"
              _zipSourcePath = proj.rootPath + proj.doc.assets_doc
              _zipSavePath = proj.fullPath + _zipPostion
              helper.archiveZip(_zipSavePath, _zipSourcePath , 'assets/')
              proj.doc.assets_doc = [proj.path + _zipPostion]

            proj.doc.preview_doc = jetpack.find( proj.doc.spec_doc[0] + '' , { matching: ['./preview'], files: false, directories: true, recursive: false} )
            # spec 处理结束

    # mockdata 仅检查文件
    proj.doc.mockdata_doc = jetpack.find( proj.path + '/mockdata' , { matching: ['./*'], files: true, directories: false, recursive: true} )
    # prototype 仅检查文件夹
    proj.doc.prototype_doc = jetpack.find( proj.path + '/prototype' , { matching: ['./*'], files: false, directories: true, recursive: false} )
    # resources 仅检查文件
    proj.doc.resources_doc = jetpack.find( proj.path + '/resources' , { matching: ['./*'], files: true, directories: false, recursive: true} )
    # review 仅检查文件夹
    proj.doc.review_doc = jetpack.find( proj.path + '/review' , { matching: ['./*'], files: false, directories: true, recursive: false} )

    console.log 'this Project File check complete!'


  # 处理文件
  do processProject = () ->

    setupProjects(foldersPath, folders)
    checkProjectContentExist(folders, projects)

    for item in projects

      checkFile(item)


      # 生成 preview 的 markdown
      if item.doc.preview_doc.length >= 1

        for _previewFolder, _previewIdx in item.doc.preview_doc

          helper.createImageMarkdown(item.rootPath + _previewFolder, item.htmlPath, 100)

      # 生成 review 的 markdown
      if item.doc.review_doc.length >= 1
        for _reviewFolder, _reviewIdx in item.doc.review_doc

          helper.createImageMarkdown(item.rootPath + _reviewFolder, item.htmlPath, 100)

      # 处理文件夹的路径名称
      for _itemDocName, _itemDocArr of item.doc

        # console.log _itemDocArr

        # 如果文件夹里有文件
        if _itemDocArr.length >= 1
          for _string, _idx in _itemDocArr

            # 准备 filelist 文字
            _domString = _string.replace(/^projects\//, '')
            # console.log _domString
            domFileListString = domFileListString + "<br>" + _domString

            # 添加../前缀
            _string = "../" + _string

            # 处理 markdown 类型
            if _string.search(/\.md$/) isnt - 1
              _string = _string.replace("\.md", '')
              # console.log _string + ' is .md'
              _itemDocArr[_idx] = helper.add_MARKDOWN_LinkString(_string)

            # 特殊处理 review_doc，preview_doc
            else if _itemDocName is 'review_doc' or _itemDocName is 'preview_doc'
              _string = _string.replace("\.md", '')
              # console.log _string + ' is .md'
              _itemDocArr[_idx] = helper.add_MARKDOWN_LinkString(_string)
              # 添加 docsify 需要的路径 + '/'
              _itemDocArr[_idx] = _itemDocArr[_idx].replace(')','/)')

            # 处理文件类型
            else if _string.search(/\.\w+$/) isnt - 1
              _itemDocArr[_idx] = helper.add_aLinkString(_string)
              # console.log _string + ' is file'

            else
              # 处理 含有html 文件夹类型，默认含有index.html
              _folderName = _string
              _folderName = helper.getFileName(_folderName)
              _string = "#{_string}/index.html"
              # console.log _string + ' is folder'
              _itemDocArr[_idx] = helper.add_Folder_aLinkString(_string, _folderName)

        # 如果文件夹里没有文件
        else
          _itemDocArr[0] = '-'
          domFileListString = domFileListString + "<br>" + "/#{_itemDocName}: none"
      domFileListString = domFileListString + "<br>" + "<font color=GAINSBORO>⬆︎ #{item.name} <br> </font>"


      rotateObjArr = (item) ->
        newFileArr = []
        length = 0
        lengths = []
        for k, v of item
          lengths.push v.length
        length = Math.max.apply(null, lengths)

        for i in [0...length]
          row = []
          for k, v of item
            if v[i] is undefined
              row.push '-'
            else row.push v[i]
          newFileArr.push row
        text = ''
        for idx in newFileArr.reverse()
          text = '|' + idx.join(" | ")  + '\n' + text


        # console.log text
        return text


      do creatProjREADMEmd = (item) ->

        MDString1 = " ###### Dashboard :  #{item.name} \n\n Publish Address： #{item.http} \n\n
        | Documents | DesignSpec | Assets | Preview | MockData | Prototype | Resource | Review |\n| : ------: | : ------: | : ------: | : ------: | : ------: | : ------: | : ------: | : ------: |\n| -*.md | - folder | - folder | - folder | - file | - folder | - file | - folder |\n "

        MDString2 = rotateObjArr(item.doc)

        MDString3 = "
        \n\n * Updated #{item.updateTime} | Render by docsify. This file is generated automatically. All modifications will be lost.*"

        MDStringTotal = MDString1 + MDString2 + MDString3

        helper.writefile(item.fullPath + '/README.md', MDStringTotal, { flag: 'w', encoding: 'utf8' } )

        # console.log MDStringTotal

      console.log item

      do creatProjListmd = (item) ->

        listStrings = listStrings + item.listText

        # console.log listStringss

  # 写 projectlist 文件到目录下
  projectListHeader = " ###### PROJECT LIST \n\n----\n\n"
  helper.writefile(targetPath + '/projects' + '/projectlist.md', projectListHeader + listStrings, { flag: 'w', encoding: 'utf8' } )

  # console.log domFileListString

  # 按钮挂载主函数事件
  document.querySelector('#button').innerHTML = '再次更新文件'
  document.getElementById("button").addEventListener 'click', startWork
  document.getElementById("button").classList.toggle('btn-disable')
  document.querySelector('#filelist').innerHTML = domFileListString


# 按钮挂载主函数事件
document.getElementById("button").addEventListener 'click', startWork
