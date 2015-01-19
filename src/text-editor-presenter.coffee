{CompositeDisposable} = require 'event-kit'

module.exports =
class TextEditorPresenter
  constructor: ({@model, @clientHeight, @clientWidth, @scrollTop, @lineHeight, @baseCharacterWidth, @lineOverdrawMargin}) ->
    @disposables = new CompositeDisposable
    @state = {}
    @subscribeToModel()
    @buildLinesState()

  destroy: ->
    @disposables.dispose()

  subscribeToModel: ->
    @disposables.add @model.onDidChange(@updateLinesState.bind(this))
    @disposables.add @model.onDidChangeSoftWrapped(@updateLinesState.bind(this))

  buildLinesState: ->
    @state.lines = {}
    @updateLinesState()

  updateLinesState: ->
    visibleLineIds = {}
    startRow = @getStartRow()
    endRow = @getEndRow()

    row = startRow
    while row < endRow
      line = @model.tokenizedLineForScreenRow(row)
      visibleLineIds[line.id] = true
      if @state.lines.hasOwnProperty(line.id)
        @updateLineState(row, line)
      else
        @buildLineState(row, line)
      row++

    for id, line of @state.lines
      unless visibleLineIds.hasOwnProperty(id)
        delete @state.lines[id]

  updateLineState: (row, line) ->
    lineState = @state.lines[line.id]
    lineState.screenRow = row
    lineState.top = row * @lineHeight
    lineState.width = @getScrollWidth()

  buildLineState: (row, line) ->
    @state.lines[line.id] =
      screenRow: row
      text: line.text
      tokens: line.tokens
      top: row * @lineHeight
      width: @getScrollWidth()

  getStartRow: ->
    startRow = Math.floor(@scrollTop / @lineHeight) - @lineOverdrawMargin
    Math.max(0, startRow)

  getEndRow: ->
    startRow = @getStartRow()
    visibleLinesCount = Math.ceil(@getClientHeight() / @lineHeight) + 1
    overdrawMargin = @lineOverdrawMargin + Math.min(@lineOverdrawMargin, startRow)
    endRow = startRow + visibleLinesCount + overdrawMargin
    Math.min(@model.getScreenLineCount(), endRow)

  getScrollWidth: ->
    contentWidth = @model.getMaxScreenLineLength() * @baseCharacterWidth
    contentWidth += 1 unless @model.isSoftWrapped() # account for cursor width
    Math.max(contentWidth, @clientWidth)

  setScrollTop: (@scrollTop) ->
    @updateLinesState()

  setClientHeight: (@clientHeight) ->
    @updateLinesState()

  getClientHeight: ->
    @clientHeight ? @model.getScreenLineCount() * @lineHeight

  setClientWidth: (@clientWidth) ->
    @updateLinesState()

  setLineHeight: (@lineHeight) ->
    @updateLinesState()

  setBaseCharacterWidth: (@baseCharacterWidth) ->
    @updateLinesState()