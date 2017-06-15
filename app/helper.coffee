fs = require('fs')
archiver = require('archiver')
jetpack = require('fs-jetpack')

targetPath = __dirname.replace(/\/\w+\.app\/.+/g, '')
jetpack = jetpack.cwd(targetPath)


# 压缩指定文件夹下的文件,保存在指定位置
this.archiveZip = (savePostion, source_file,pathInZip) ->
  output = fs.createWriteStream(savePostion)
  archive = archiver('zip')

  # console.log savePostion, source_file
  output.on 'close', ->
    console.log ( "complete ZIP:  #{ savePostion }" + archive.pointer() + ' total bytes')

  archive.on 'error', (err) ->
    throw err

  # 目标文件夹
  archive.directory(source_file, pathInZip)
  archive.pipe(output)
  archive.finalize()


# 生成image文件夹的.markdown,保存在该文件夹下面,文件名为 README.md
this.createImageMarkdown = (fullFolderPath,htmlPath,imgHeight) ->
  _files = jetpack.find( fullFolderPath , { matching: ['*.png', '*.jpg'], files: true, directories: false, recursive: false})

  htmlString = ''

  for item in _files

    htmlString = htmlString + "<img src=\" #{htmlPath}#{item}\" alt=\"Drawing\" style=\"height: #{imgHeight}px;\"/>" + '\n'

  jetpack.write(fullFolderPath + '/README.md',htmlString)

this.getFileName = (uri) ->
  # arr = []
  arr = uri.split("/")
  uri = arr.pop()
  return uri

this.add_aLinkString = (string) ->
  _filename = this.getFileName(string)
  return "<a href=\"#{string}\" target=\"_blank\"> #{_filename} <\/a> "

this.add_Folder_aLinkString = (string,folderName) ->
  # _filename =  this.getFileName(string)
  # _folderName =  this.getFileName(_filename)
  # console.log _filename
  return "<a href=\"#{string}\" target=\"_blank\"> #{folderName} <\/a> "

this.add_MARKDOWN_LinkString = (string) ->
  _filename = this.getFileName(string)
  return "[#{_filename}](#{string})"

this.add_IndexHTML_String = (string) ->
  return "#{string}/index.html"

this.writefile = (fileName, content, dir) ->
  fs.writeFileSync fileName, content, { flag: 'w', encoding: 'utf8' }, (err) ->
    if err?
      throw err
