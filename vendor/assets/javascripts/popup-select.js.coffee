#= require 'sugar'
#= require 'dialog-plus-min'
#= require 'dialog-config'

jQuery ->
  root = this

  $(".drop_select").prop('readonly', 'true').click ->
    thisInput = this
    thisDom = $(this)
    dropSelect thisInput, thisDom

  # 主函数
  dropSelect = (thisInput, thisDom) ->
    thisDomId = thisDom.attr('id')
    attributeArray = [
        ['drop-data', ''], ['name-split', ''], ['checkbox-type', 0], ['non-check', true]
        ['drop-limit', 0], ['click-open', false], ['drop-with', '145px']
        ['drop-tree', false], ['join-remark', '>>']
      ]
    attributeArray.each (i)->
      thisInput[i[0].camelize(false)] = if thisDom.data(i[0]) == undefined then i[1] else thisDom.data(i[0])
    thisInput.dialogTitle = if thisInput.dropLimit > 0 then "请选择[最多 #{thisInput.dropLimit} 项]" else "请选择"
    dialogDom = dialog.get "float_#{ thisDomId }"

    #  关闭所有下拉选择窗口
    i.close() for i in dialog.list when i isnt dialogDom

    dialogDom = dialog
      id: "float_#{ thisDomId }"
      title: thisInput.dialogTitle
      width: thisInput.dialogWidth
      button: [
        {
          value: '取消'
          callback: ->
            this.close()
            false
        },
        {
          value: '确定'
          callback: ->
            afterOk(thisInput, thisDom, dialogDom)
            false
        }
      ]
      follow: thisInput
      quickClose: true
      cancelDisplay: false
      zIndex: 2000
      width: '100%'
      height: '100%'
      left: '0%'
      top: '0%'
    dialogDom.show()

    # 不是以/开头的直接取值，否则是AJAX抓取的路径
    if thisInput.dropData.has("/")
      # do nothing
    else
      content = getDropOpts(thisInput, thisDom, thisInput.dropData, dialogDom, thisInput.dialogWidth)
      dialogDom.content(content)

    # 默认勾上已选项
    do ->
      value = if thisDom.val() is "" then thisDom.attr("value") else thisDom.val()
      domValue = value.split(",")
      allNodes = $("#opts_float_#{ thisDomId} input[name='drop_option[]']")
      allNodes.toArray().each (i)->
        $(i).prop('checked', true) if $(i).val() in domValue

  # 非树形的AJAX返回结果处理
  getDropOpts = (thisInput, thisDom, data, dialogDom, dialogWidth)->
    isRadio = thisInput.dropLimit is 1
    thisDomId = thisDom.attr('id')
    cont = "<div id='opts_float_#{ thisDomId }'>";
    if data.has("出错提示：") || data.isBlank()
      cont += "<div id='float_tips' class='float_tips'>抱歉，没有可选项！#{ data }</div>"
    else if data.has("<") && data.has(">")
      # 含有HTML标签的不做任何加工，显示原本的内容
      cont = data
    else
      opt = data.split("|").compact(true)
      opt.each (i)->
        cont += "<div><label><input class='drop-option' type='#{ if isRadio then 'radio' else 'checkbox' }' value='#{i}' name='drop_option[]'/>#{i}</label></div>"
      cont += "</div>"
      cont += '<br><div class="float_tips"></div>'
      setTimeout(->
        $('input.drop-option').click -> checkDropLimit(thisInput, thisDomId)
        if isRadio
          $('input.drop-option').click ->
            afterOk(thisInput, thisDom, dialogDom) if $(@).is(':checked')
      , 0)
    cont

  afterOk = (thisInput, thisDom, dialogDom)->
    thisDomId = thisDom.attr('id')
    checkedNodes = $("#opts_float_#{ thisDomId} input[name='drop_option[]']:checked")
    if checkDropLimit(thisInput)
      str = ""
      checkedNodes.toArray().each (i)-> str += (if str is "" then "" else ",") + $(i).val()
      thisDom.val(str).change()
      dialogDom.close().remove()

  checkDropLimit = (thisInput, thisDomId) ->
    checkedNodes = $("#opts_float_#{ thisDomId} input[name='drop_option[]']:checked")
    if thisInput.dropLimit > 0 and checkedNodes.length > thisInput.dropLimit
      $("div.ui-dialog div.float_tips").html("最多只能选 #{ thisInput.dropLimit } 项")
      return false
    else
      $("div.ui-dialog div.float_tips").html("")
      return true