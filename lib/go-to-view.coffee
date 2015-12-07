path = require 'path'
SymbolsView = require './symbols-view'
TagReader = require './tag-reader'
{$$} = require 'atom-space-pen-views'
fuzzaldrin = require 'fuzzaldrin'

module.exports =
class GoToView extends SymbolsView
  toggle: ->
    if @panel.isVisible()
      @cancel()
    else
      @populate()

  detached: ->
    @resolveFindTagPromise?([])

  getFilterKey: -> 'file'

  viewForItem: ({position, name, file, directory}) ->
    # Style matched characters in search results
    matches = fuzzaldrin.match(file, @getFilterQuery())

    if atom.project.getPaths().length > 1
      file = path.join(path.basename(directory), file)

    $$ ->
      @li class: 'two-lines', =>
        if position?
          @div "#{name}:#{position.row + 1}", class: 'primary-line'
        else
          @div name, class: 'primary-line'
        @div class: 'secondary-line', => SymbolsView.highlightMatches(this, file, matches)

  findTag: (editor) ->
    @resolveFindTagPromise?([])

    new Promise (resolve, reject) =>
      @resolveFindTagPromise = resolve
      TagReader.find editor, (error, matches=[]) ->
        if error
          reject(error)
        else
          resolve(matches)

  populate: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    @findTag(editor).then (matches) =>
      tags = []
      for match in matches
        position = @getTagLine(match)
        continue unless position
        match.name = path.basename(match.file)
        tags.push(match)

      if tags.length is 1
        @openTag(tags[0])
      else if tags.length > 0
        @setItems(tags)
        @attach()
