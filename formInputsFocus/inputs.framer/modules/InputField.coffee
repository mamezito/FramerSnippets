################################################################################
# Created 07 Jan 2016 by Jordan Robert Dobson / @jordandobson / JordanDobson.com
################################################################################
#
# Valid & Tested InputField Types: 
# 	"text", "email", "number", "number-only", "url", "tel", "password", "search"
# 	"time", "month", "date", "datetime-local"
# 
# The time & date types REQUIRE the value property is in a correct format & IGNORE the placeholder property.
# 
# Here's a few examples to use for the value: property when you create them:
#
# 	* time: "12:38"
# 	* month: "2016-01"
# 	* date: "2016-01-04"
# 	* datetime-local: "2016-01-04T12:44:31.192"
#
# NOTES / 
# 	Some types work better than others on mobile or display differently than desktop.
# 	All properties will work with input type "text" but may not work with other types.
# 	Some events won't fire if you enter incorrect content for the field type: i.e. "hello" for input type "number".
# 	Find more patterns for Valid and Invalid events at http://html5pattern.com
# 
################################################################################


class exports.InputField extends Layer

	PATTERN_NUMBER = "[0-9]*"
	
	INPUT_HIDE_PSUEDO_UI  = "{ -webkit-appearance: none; display: none; }"
	INPUT_SELECTOR_NUMBER = "input[type=number]::-webkit-inner-spin-button, input[type=number]::-webkit-outer-spin-button"
	INPUT_SELECTOR_SEARCH = "input[type=search]::-webkit-search-cancel-button"
	
	Events.Input   = "InputField.OnInput"
	Events.Focus   = "InputField.OnFocus"
	Events.Blur    = "InputField.OnBlur"
	Events.Valid   = "InputField.OnValid"
	Events.Invalid = "InputField.OnInvalid"
	Events.Match   = "InputField.OnMatch"
	
	@define "value",
		get: ->
			@input.value
			
		set: (v) ->
			return unless v
			if @input
				@changeInputValue v


	constructor: (@options={}) ->
	
		@isNumber = false
		@isSearch = false
		
		@isEmpty  = true
		@isValid  = null
		@originalTextColor = null
		
		# Make sure we set the Checking Flag
		@shouldCheckValidity = true if @options.pattern? or @options.match?

		# Make sure this is in px
		@options.lineHeight = "#{@options.lineHeight}px" if @options.lineHeight?
		 								
		# Framer Layer Props
		@options.name             ?= "#{@options.type}Input"
		@options.color            ?= "black"
		@options.backgroundColor  ?= ""
		@options.borderRadius     ?= 0

		# Custom Layer Props		
		@options.type             ?= "text"
		@options.fontSize         ?= 32
		@options.fontWeight       ?= 300
		@options.fontFamily       ?= "-apple-system, Helvetica Neue"
		@options.lineHeight       ?= 1.25
		@options.indent           ?= 0
		@options.placeHolderFocus ?= null
		@options.placeHolderColor ?= null

		super @options
		
		# Adjust a few things for various types
		
		switch @options.type
			when "search" then @isSearch = true
			when "number" then @isNumber = true
			when "numbers-only", "number-only"
				@isNumber = true
				@options.type    = if @options.pattern? then "number"          else "text"
				@options.pattern = if @options.pattern? then @options.pattern else PATTERN_NUMBER
		
		@html += switch
			when @isNumber then "<style type='text/css'>#{INPUT_SELECTOR_NUMBER}#{INPUT_HIDE_PSUEDO_UI}</style>"
			when @isSearch then "<style type='text/css'>#{INPUT_SELECTOR_SEARCH}#{INPUT_HIDE_PSUEDO_UI}</style>"
			else ""

		if @options.placeHolderColor?
			@html += "<style type='text/css'>::-webkit-input-placeholder { color: #{@options.placeHolderColor}; } ::-moz-placeholder { color: #{@options.placeHolderColor}; } :-ms-input-placeholder { color: #{@options.placeHolderColor}; } ::-ms-input-placeholder { color: #{@options.placeHolderColor}; } :placeholder-shown { color: #{@options.placeHolderColor}; }</style>"
			
		# Create The Input
		
		@input = document.createElement "input"
		
		@input.type        = @options.type
		@input.value       = @options.value                  if @options.value?
		@input.placeholder = @options.placeHolder            if @options.placeHolder?
		@input.pattern     = @options.pattern                if @options.pattern?
		@input.setAttribute("maxLength", @options.maxLength) if @options.maxLength?
		@input.setAttribute("autocapitalize", (if @options.autoCapitalize is true then "on" else "off"))
		@input.setAttribute("autocomplete",   (if @options.autoComplete   is true then "on" else "off"))
		@input.setAttribute("autocorrect",    (if @options.autoCorrect    is true then "on" else "off"))
		
		@_element.appendChild @input
		
		# Setup Values
		@isEmpty           = !(@options.value?.length > 0)
		@originalTextColor = @options.color
		
		# Setup Input Style
		
		inputStyle =
			font: "#{@options.fontWeight} #{@options.fontSize}px/#{@options.lineHeight} #{@options.fontFamily}"
			outline: "none"
			textIndent: "#{@options.indent}px"
			backgroundColor: "transparent"
			height: "100%"
			width:  "100%"
			pointerEvents: "none"
			margin: "0"
			padding: "0"
			"-webkit-appearance": "none"
			
		@input.style[key]  = val for key, val of inputStyle
		@input.style.color = @options.color if @options.color?
		
		@input.onfocus = =>
			document.body.scrollTop = 0
			@input.placeholder = @options.placeHolderFocus if @options.placeHolderFocus?
			document.body.scrollTop = 0
			@emit(Events.Focus, @input.value, @)

		@input.onblur  = =>
			document.body.scrollTop = 0
			unless @input.placeholder is @options.placeHolder or !@options.placeHolder?
				@input.placeholder = @options.placeHolder
			@emit(Events.Blur, @input.value, @)

		@input.oninput = =>
			@isEmpty = !( @input.value?.length > 0)
			@emit(Events.Input, @input.value, @)
			@checkValidity()
			
		@on Events.TouchEnd, -> @input.focus()
		@on "change:color",  -> @changeInputTextColor()
		
	checkValidity: ->
		return unless @shouldCheckValidity

		if @options.pattern?
			validity = @input.checkValidity()
			@isEmpty = !( @input.value?.length > 0)
			
			if @isValid isnt validity or @isEmpty
				if @isEmpty or !validity
					@isValid = false
					@emit(Events.Invalid, @input.value, @)
				else
					@isValid = true
					@emit(Events.Valid,   @input.value, @)
					
		if @checkMatch()
			@isValid = true
			@emit(Events.Match, @input.value, @)
			
	checkMatch: ->
		return false unless @options.match?
		if Array.isArray(@options.match)
			for match in @options.match
				return true if @input.value.indexOf(match) > -1
		else
			return true if @input.value.indexOf(@options.match) > -1
		return false
			
	clear: ->
		@input.value = ""
		@isValid = null
		@isEmpty = true
		
	changeInputTextColor: -> 
		@input.style.color = @color.toHexString()
	
	changeInputValue: (v) ->
		@input.value = v
		@input.oninput()
		
		
		