
class Simditor extends Widget
  @connect Util
  @connect UndoManager
  @connect InputManager
  @connect Formatter
  @connect Selection
  @connect Toolbar

  @count: 0

  opts:
    textarea: null
    placeholder: 'Type here...'
    defaultImage: 'images/image.png'

  _init: ->
    @textarea = $(@opts.textarea);

    unless @textarea.length
      throw new Error 'simditor: param textarea is required.'
      return

    editor = @textarea.data 'simditor'
    if editor?
      editor.destroy()

    @id = ++ Simditor.count
    @_render()

    form = @textarea.closest 'form'
    if form.length
      form.on 'submit.simditor-' + @id, =>
        @sync()
      form.on 'reset.simditor-' + @id, =>
        @setValue ''

    @setValue @textarea.val() ? ''

    @on 'valuechanged', =>
      @_placeholder()

    setTimeout =>
      @trigger 'valuechanged'
    , 0

    # Disable the resizing of `img` and `table`
    #if @browser.mozilla
      #document.execCommand "enableObjectResizing", false, "false"
      #document.execCommand "enableInlineTableEditing", false, "false"

  _tpl:"""
    <div class="simditor">
      <div class="simditor-wrapper">
        <div class="simditor-placeholder"></div>
        <div class="simditor-body" contenteditable="true">
        </div>
      </div>
    </div>
  """

  _render: ->
    @el = $(@_tpl).insertBefore @textarea
    @wrapper = @el.find '.simditor-wrapper'
    @body = @wrapper.find '.simditor-body'
    @placeholderEl = @wrapper.find('.simditor-placeholder').append(@opts.placeholder)

    @el.append(@textarea)
      .data 'simditor', this
    @textarea.data('simditor', this)
      .hide()
      .blur()
    @body.attr 'tabindex', @textarea.attr('tabindex')

    if @util.os.mac
      @el.addClass 'simditor-mac'
    else if @util.os.linux
      @el.addClass 'simditor-linux'

  _placeholder: ->
    children = @body.children()
    if children.length == 0 or (children.length == 1 and @util.isEmptyNode(children))
      @placeholderEl.show()
    else
      @placeholderEl.hide()

  setValue: (val) ->
    @textarea.val val
    @body.html val

    @formatter.format()
    @formatter.decorate()

  getValue: () ->
    @sync()

  sync: ->
    cloneBody = @body.clone()

    # generate `a` tag automatically
    @formatter.autolink cloneBody

    # remove empty `p` tag at the end of content
    lastP = cloneBody.children().last 'p'
    while lastP.is 'p' and !lastP.text() and !lastP.find('img').length
      emptyP = lastP
      lastP = lastP.prev 'p'
      emptyP.remove()

    val = @formatter.undecorate cloneBody
    @textarea.val val
    val

  destroy: ->
    @trigger 'simditordestroy'

    @textarea.closest 'form'
      .off '.simditor .simditor-' + @id

    @selection.clear()

    @textarea.insertBefore(@el)
      .hide()
      .val ''
      .removeData 'simditor'

    @el.remove()
    $(document).off '.simditor-' + @id
    $(window).off '.simditor-' + @id
    @off()


window.Simditor = Simditor
window.Simditor.Plugin = Plugin
