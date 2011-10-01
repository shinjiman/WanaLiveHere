-- coronaui_ui.lua ( based on ui.lua, modified to work with coronaui.lua )

-- Version 1.5 (works with multitouch, adds setText() method to buttons)
--
-- Copyright (C) 2010 ANSCA Inc. All Rights Reserved.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of 
-- this software and associated documentation files (the "Software"), to deal in the 
-- Software without restriction, including without limitation the rights to use, copy, 
-- modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
-- and to permit persons to whom the Software is furnished to do so, subject to the 
-- following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all copies 
-- or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.

----------------------------------------------------

module(..., package.seeall)

-----------------
-- Helper function for newButton utility function below
local function newButtonHandler( self, event )

	local result = true
	local default, over, defaultLeft, defaultRight, overLeft, overRight
	local customButton = false
	
	if self[7] then
		customButton = true
		defaultLeft = self[1]
		default = self[2]
		defaultRight = self[3]
	
		overLeft = self[4]
		over = self[5]
		overRight = self[6]
	else
		default = self[1]
		over = self[2]
	end
	
	-- General "onEvent" function overrides onPress and onRelease, if present
	local onEvent = self._onEvent
	
	local onPress = self._onPress
	local onRelease = self._onRelease

	local buttonEvent = {}
	if (self._id) then
		buttonEvent.id = self._id
	end

	local phase = event.phase
	if "began" == phase then
		if over then
			over.isVisible = true
			default.isVisible = false
			
			if customButton then
				defaultLeft.isVisible = default.isVisible
				defaultRight.isVisible = default.isVisible
			
				overLeft.isVisible = over.isVisible
				overRight.isVisible = over.isVisible
			end
		end

		if onEvent then
			buttonEvent.phase = "press"
			result = onEvent( buttonEvent )
		elseif onPress then
			result = onPress( event )
		end

		-- Subsequent touch events will target button even if they are outside the stageBounds of button
		display.getCurrentStage():setFocus( self, event.id )
		self.isFocus = true
		
	elseif self.isFocus then
		local bounds = self.stageBounds
		local x,y = event.x,event.y
		local isWithinBounds = 
			bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y

		if "moved" == phase then
			if over then
				-- The rollover image should only be visible while the finger is within button's stageBounds				
				default.isVisible = not isWithinBounds
				over.isVisible = isWithinBounds
				
				if customButton then
					defaultLeft.isVisible = default.isVisible
					defaultRight.isVisible = default.isVisible
				
					overLeft.isVisible = over.isVisible
					overRight.isVisible = over.isVisible
				end
			end
			
		elseif "ended" == phase or "cancelled" == phase then 
			if over then
				-- if this button is part of tab group, de-select other buttons
				if self.parent.myName == "tabGroup" then
					local i
					local numItems = #self.parent.buttonsList
					
					for i=1,numItems,1 do
						self.parent.buttonsList[i][1].isVisible = true
						self.parent.buttonsList[i][2].isVisible = true
						self.parent.buttonsList[i][3].isVisible = true
						
						self.parent.buttonsList[i][4].isVisible = false
						self.parent.buttonsList[i][5].isVisible = false
						self.parent.buttonsList[i][6].isVisible = false
					end
				end
				
				-- if this button is part of tab group, keep it selected
				if self.parent.myName == "tabGroup" then
					default.isVisible = false
					over.isVisible = true
				else
					default.isVisible = true
					over.isVisible = false
				end
				
				if customButton then
					defaultLeft.isVisible = default.isVisible
					defaultRight.isVisible = default.isVisible
				
					overLeft.isVisible = over.isVisible
					overRight.isVisible = over.isVisible
				end
			end
			
			if "ended" == phase then
				-- Only consider this a "click" if the user lifts their finger inside button's stageBounds
				if isWithinBounds then
					if onEvent then
						buttonEvent.phase = "release"
						result = onEvent( buttonEvent )
					elseif onRelease then
						result = onRelease( event )
					end
				end
			end
			
			-- Allow touch events to be sent normally to the objects they "hit"
			display.getCurrentStage():setFocus( self, nil )
			self.isFocus = false
		end
	end

	return result
end


---------------
-- Button class

function newButton( params )
	local button, defaultSrc , defaultX , defaultY , overSrc , overX , overY , size, font, textColor, offset
	local imageLeft, imageMid, imageRight, overLeft, overMid, overRight
	
	imageLeft = params.imageLeft
	imageMid = params.imageMid
	imageRight = params.imageRight
	
	btnoverLeft = params.overLeft
	btnoverMid = params.overMid
	btnoverRight = params.overRight
	
	tabLeft = params.tabLeft
	tabRight = params.tabRight
	
	tabOverLeft = params.tabOverLeft
	tabOverRight = params.tabOverRight
	
	
	if params.defaultSrc then
		button = display.newGroup()
		default = display.newImageRect ( params.defaultSrc , params.defaultX , params.defaultY )
		button:insert( default, true )
	else
		button = display.newGroup()
		if params.isMidTab or params.isRightTab then
			if tabLeft then
				defaultLeft = display.newImageRect( tabLeft, 6, 30 )
			else
				defaultLeft = display.newImageRect( "coronaui_tableft.png", 6, 30 )
			end
				
		else
			if imageLeft then
				defaultLeft = display.newImageRect( imageLeft, 6, 30 )
			else
				defaultLeft = display.newImageRect( "coronaui_buttonleft.png", 6, 30 )
			end
		end
		button:insert( defaultLeft, true )
		
		local midWidth = 53
		if params.width then
			midWidth = params.width - 12
		end
		if imageMid then
			default = display.newImageRect( imageMid, midWidth, 30 )
		else
			default = display.newImageRect( "coronaui_buttonmid.png", midWidth, 30 )
		end
		
		button:insert( default, true )
		
		if params.isMidTab or params.isLeftTab then
			if tabRight then
				defaultRight = display.newImageRect( tabRight, 6, 30 )
			else
				defaultRight = display.newImageRect( "coronaui_tabright.png", 6, 30 )
			end
		else
			if imageRight then
				defaultRight = display.newImageRect( imageRight, 6, 30 )
			else
				defaultRight = display.newImageRect( "coronaui_buttonright.png", 6, 30 )
			end
		end
		button:insert( defaultRight, true )
		
		local totalHalfWidth = (default.width * 0.5) + (defaultRight.width * 0.5)
		
		-- calclulate location
		defaultLeft.x = -totalHalfWidth
		
		default.x = defaultLeft.x + (defaultLeft.width * 0.5) + (default.width * 0.5)
		default.y = defaultLeft.y
		
		defaultRight.x = default.x + (default.width * 0.5) + (defaultRight.width * 0.5)
		defaultRight.y = default.y
	end
		
	
	if params.overSrc then
		over = display.newImageRect ( params.overSrc , params.overX , params.overY )
		over.isVisible = false
		button:insert( over, true )
	else
		if params.isMidTab or params.isRightTab then
			if tabOverLeft then
				overLeft = display.newImageRect( tabOverLeft, 6, 30 )
			else
				overLeft = display.newImageRect( "coronaui_tableft-over.png", 6, 30 )
			end
		else
			if btnoverLeft then
				overLeft = display.newImageRect( btnoverLeft, 6, 30 )
			else
				overLeft = display.newImageRect( "coronaui_buttonleft-over.png", 6, 30 )
			end
		end
		button:insert( overLeft, true )
		
		local midWidth = 53
		if params.width then
			midWidth = params.width - 12
		end
		
		if btnoverMid then
			over = display.newImageRect( btnoverMid, midWidth, 30 )
		else
			over = display.newImageRect( "coronaui_buttonmid-over.png", midWidth, 30 )
		end
		button:insert( over, true )
		
		if params.isMidTab or params.isLeftTab then
			if tabOverRight then
				overRight = display.newImageRect( tabOverRight, 6, 30 )
			else
				overRight = display.newImageRect( "coronaui_tabright-over.png", 6, 30 )
			end
		else
			if btnoverRight then
				overRight = display.newImageRect( btnoverRight, 6, 30 )
			else
				overRight = display.newImageRect( "coronaui_buttonright-over.png", 6, 30 )
			end
		end
		button:insert( overRight, true )
			
		local totalHalfWidth = (over.width * 0.5) + (overRight.width * 0.5)
		
		-- calclulate location
		overLeft.x = -totalHalfWidth
		
		over.x = overLeft.x + (overLeft.width * 0.5) + (over.width * 0.5)
		over.y = overLeft.y
		
		overRight.x = over.x + (over.width * 0.5) + (overRight.width * 0.5)
		overRight.y = over.y
		
		overLeft.isVisible = false
		over.isVisible = false
		overRight.isVisible = false
	end
	
	-- Public methods
	function button:setText( newText )
	
		local labelText = self.text
		if ( labelText ) then
			labelText:removeSelf()
			self.text = nil
		end

		local labelShadow = self.shadow
		if ( labelShadow ) then
			labelShadow:removeSelf()
			self.shadow = nil
		end

		local labelHighlight = self.highlight
		if ( labelHighlight ) then
			labelHighlight:removeSelf()
			self.highlight = nil
		end
		
		if ( params.size and type(params.size) == "number" ) then size=params.size else size=20 end
		if ( params.font ) then font=params.font else font=native.systemFontBold end
		if ( params.textColor ) then textColor=params.textColor else textColor={ 255, 255, 255, 255 } end
		
		size = size * 2
		
		-- Optional vertical correction for fonts with unusual baselines (I'm looking at you, Zapfino)
		if ( params.offset and type(params.offset) == "number" ) then offset=params.offset else offset = 0 end
		
		if ( params.emboss ) then
			-- Make the label text look "embossed" (also adjusts effect for textColor brightness)
			local textBrightness = ( textColor[1] + textColor[2] + textColor[3] ) / 3
			
			labelHighlight = display.newText( newText, 0, 0, font, size )
			if ( textBrightness > 127) then
				labelHighlight:setTextColor( 255, 255, 255, 20 )
			else
				labelHighlight:setTextColor( 255, 255, 255, 140 )
			end
			button:insert( labelHighlight, true )
			labelHighlight.x = labelHighlight.x + 1.5; labelHighlight.y = labelHighlight.y + 1.5 + offset
			self.highlight = labelHighlight

			labelShadow = display.newText( newText, 0, 0, font, size )
			if ( textBrightness > 127) then
				labelShadow:setTextColor( 0, 0, 0, 128 )
			else
				labelShadow:setTextColor( 0, 0, 0, 20 )
			end
			button:insert( labelShadow, true )
			labelShadow.x = labelShadow.x - 1; labelShadow.y = labelShadow.y - 1 + offset
			self.shadow = labelShadow
			
			labelHighlight.xScale = .5; labelHighlight.yScale = .5
			labelShadow.xScale = .5; labelShadow.yScale = .5
		end
		
		labelText = display.newText( newText, 0, 0, font, size )
		labelText:setTextColor( textColor[1], textColor[2], textColor[3], textColor[4] )
		button:insert( labelText, true )
		labelText.y = labelText.y + offset
		self.text = labelText
		
		labelText.xScale = .5; labelText.yScale = .5
	end
	
	if params.text then
		button:setText( params.text )
	end
	
	if ( params.onPress and ( type(params.onPress) == "function" ) ) then
		button._onPress = params.onPress
	end
	if ( params.onRelease and ( type(params.onRelease) == "function" ) ) then
		button._onRelease = params.onRelease
	end
	
	if (params.onEvent and ( type(params.onEvent) == "function" ) ) then
		button._onEvent = params.onEvent
	end
	
	-- set button to active (meaning, can be pushed)
	button.isActive = true
	
	-- Set button as a table listener by setting a table method and adding the button as its own table listener for "touch" events
	button.touch = newButtonHandler
	button:addEventListener( "touch", button )

	if params.x then
		button.x = params.x
	end
	
	if params.y then
		button.y = params.y
	end
	
	if params.id then
		button._id = params.id
	end

	return button
end


--------------
-- Label class

function newLabel( params )
	local labelText
	local size, font, textColor, align
	local t = display.newGroup()
	
	if ( params.bounds ) then
		local bounds = params.bounds
		local left = bounds[1]
		local top = bounds[2]
		local width = bounds[3]
		local height = bounds[4]
	
		if ( params.size and type(params.size) == "number" ) then size=params.size else size=20 end
		if ( params.font ) then font=params.font else font=native.systemFontBold end
		if ( params.textColor ) then textColor=params.textColor else textColor={ 255, 255, 255, 255 } end
		if ( params.offset and type(params.offset) == "number" ) then offset=params.offset else offset = 0 end
		if ( params.align ) then align = params.align else align = "center" end
		
		if ( params.text ) then
			labelText = display.newText( params.text, 0, 0, font, size )
			labelText:setTextColor( textColor[1], textColor[2], textColor[3], textColor[4] )
			t:insert( labelText )
			-- TODO: handle no-initial-text case by creating a field with an empty string?
	
			if ( align == "left" ) then
				labelText.x = left + labelText.stageWidth * 0.5
			elseif ( align == "right" ) then
				labelText.x = (left + width) - labelText.stageWidth * 0.5
			else
				labelText.x = ((2 * left) + width) * 0.5
			end
		end
		
		labelText.y = top + labelText.stageHeight * 0.5

		-- Public methods
		function t:setText( newText )
			if ( newText ) then
				labelText.text = newText
				
				if ( "left" == align ) then
					labelText.x = left + labelText.stageWidth / 2
				elseif ( "right" == align ) then
					labelText.x = (left + width) - labelText.stageWidth / 2
				else
					labelText.x = ((2 * left) + width) / 2
				end
			end
		end
		
		function t:setTextColor( r, g, b, a )
			local newR = 255
			local newG = 255
			local newB = 255
			local newA = 255

			if ( r and type(r) == "number" ) then newR = r end
			if ( g and type(g) == "number" ) then newG = g end
			if ( b and type(b) == "number" ) then newB = b end
			if ( a and type(a) == "number" ) then newA = a end

			labelText:setTextColor( r, g, b, a )
		end
	end
	
	-- Return instance (as display group)
	return t
	
end