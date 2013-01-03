class Didh.Routers.AppRouter extends Backbone.Router

	initialLoad: true

	initialize: (options) ->
		@static = options.static
		@setupLinkClickHandlers(options)
		@setupCollections(options)
		@setupViews(options)
		@tocView.render()
		@annotator.render()
		@feedbackView.render()

		# window.addEventListener('orientationchange', () ->
		# 	Backbone.Mediator.publish('app:orientationchange');
		# , false)

	routes:
		"part/:id"			: "showPart"
		"text/:id"			: "showText"
		"*catchall"			: "setDefaultText" # Backbone, wtf does this work?

	setupViews: (options) ->
		@banner= new Didh.Views.Frontend.BannerView(el: $("#backbone-bannerView"))
		@annotator = new Didh.Views.Frontend.AnnotatorView(el: $("#backbone-annotatorView"), keywords: @keywords, annotations: @annotations, parts: @parts, texts: @texts)
		@hudView = new Didh.Views.Frontend.HudView(el: $("#backbone-hudView"), texts: @texts )
		@tocView = new Didh.Views.Frontend.TocView(el: $("#backbone-tocView"), parts: @parts, texts: @texts, router: @ )
		@feedbackView = new Didh.Views.Frontend.FeedbackView(el: $("#backbone-feedbackView"), linkedPane: @tocView, texts: @texts, static: @static)

	setupCollections: (options) ->
		@parts = new Didh.Collections.PartsCollection()
		@parts.reset options.parts
		@texts = new Didh.Collections.TextsCollection()
		@texts.reset options.texts
		@annotations = new Didh.Collections.AnnotationsCollection()
		@annotations.reset options.annotations
		@keywords = new Didh.Collections.KeywordsCollection()

	setupLinkClickHandlers: (options) ->
		$(document).on "click", "a[href^='/debates/']", (event) =>
			href = $(event.currentTarget).attr('href')
			if !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey
				event.preventDefault()

				# Remove root part of the URL and hash bangs (backward compatablility)
				url = href.replace(/^\/debates/,'').replace('\#\!\/','')

				# Instruct Backbone to trigger routing events
				@navigate url, { trigger: true }

				return false

		$(document).on "click", "a[href^='#']", (event) =>
			href = $(event.currentTarget).attr('href')
			if !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey
				anchor = href.replace(/^#/,'');
				$('html, body').animate({scrollTop: $('#' + anchor).offset().top - 100}, 250)
				return false

	setDefaultText: () ->
		part = _.first(@parts.where({label: "Introduction"}))
		text = _.first(@texts.where({part: part.id}))
		@setActiveText(text.id)

	renderTextView: () ->
		@textView.render()

	showText: (textId) ->
		if @static == true then window.location.reload()
		@tocView.goToPosition(1)
		@feedbackView.goToPosition(1)
		@setActiveText(textId)

	setActiveText: (id) ->

		id = parseInt(id)
		@requestedTextId = id
		text = @texts.get(id)

		# Don't set the active text if the requested text is the same as the active text
		if id != @texts.getActiveTextId()
			if text.get('isLoaded')
				@texts.setActiveText(text.get('id'))
				@feedbackView.setModel(text)
				@feedbackView.render()
				@textView = new Didh.Views.Frontend.TextView(el: $("#backbone-textView"), model: text, visualization: @feedbackView.getVisualizationType(), parts: @parts, texts: @texts )
				@textView.render()
			else
				text.fetch({
					success: =>
						@textView = new Didh.Views.Frontend.TextView(el: $("#backbone-textView"), model: text, visualization: @feedbackView.getVisualizationType(), parts: @parts, texts: @texts )
						@texts.setActiveText(text.get('id'))
						@feedbackView.setModel(text)
						text.set({isLoaded: true})
				})
			@parts.setActivePart(text.get('part'))

	showPart: (id) ->
		@annotator.stopAnnotating()
		part = @parts.get(id)
		if !@texts.getActiveTextId()
			@requestedPartId = id
			text = _.first(@texts.where({part: part.id}))
			@setActiveText(text.id)

		@tocView.showPart(part)

	getRequestedText: () ->
		if @requestedTextId?
			@texts.get(@requestedTextId)
		else
			return null

	init: ->

