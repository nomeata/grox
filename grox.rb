#!/usr/bin/ruby

# ./grox.rb <dir>
#   +left, +right, flip: relative movement
#   -left, -right, -inverted: toggle movement
#   left, right, normal, inverted: absolute movement

# devices to manipulate
$screen = 'eDP-1'
$touchscreen1 = 'Wacom Pen and multitouch sensor Finger touch'
$touchscreen2 = 'Wacom Pen and multitouch sensor Pen stylus'
$touchscreen3 = 'Wacom Pen and multitouch sensor Pen eraser'
$touchpad = 'SynPS/2 Synaptics TouchPad'
$keyboard = 'AT Translated Set 2 keyboard'

# disable keypad and touchpad on all but normal orientation
$controlKeys = false

# runs cmd and greps output to find orientation
$orientationCmd = 'xrandr'
$orientationRE = /\s*#{$screen}\s+\w+\s+\w+\s+[x+\d]+\s+(|left|right|inverted)\s*\(/

# default direction
$defaultDirection = '-right'


# CODE

def main()
    direction = $defaultDirection

    if ARGV.length > 0
        direction = ARGV[0]
    end

    doOrientate(getNewOrientation(direction))
end


def orientateCmd(orientation, transform)
    rotateScreen = "xrandr --output #{$screen}" +
                         " --rotate #{orientation}";
    rotateTouchscreen1 = "xinput --set-prop '#{$touchscreen1}'" +
                              " --type=float" +
                              " 'Coordinate Transformation Matrix'" +
                              " #{transform}"
    rotateTouchscreen2 = "xinput --set-prop '#{$touchscreen2}'" +
                              " --type=float" +
                              " 'Coordinate Transformation Matrix'" +
                              " #{transform}"
    rotateTouchscreen3 = "xinput --set-prop '#{$touchscreen3}'" +
                              " --type=float" +
                              " 'Coordinate Transformation Matrix'" +
                              " #{transform}"
    controlKeys = ""
    if $controlKeys
        setCmd = orientation == 'normal' ? 'xinput --enable ' 
                                         : 'xinput --disable '
        controlKeys = "#{setCmd} '#{$touchpad}'; #{setCmd} '#{$keyboard}';"
    end

    return controlKeys +
           rotateScreen + ';' +
           rotateTouchscreen1 + ';' +
           rotateTouchscreen2 + ';' +
           rotateTouchscreen3 + ';'
end


def doOrientate(orientation)
    case orientation
    when 'normal'
        `#{orientateCmd('normal', '1 0 0 0 1 0 0 0 1')}`
    when 'left'
        `#{orientateCmd('left', '0 -1 1 1 0 0 0 0 1')}`
    when 'right'
        `#{orientateCmd('right', '0 1 0 -1 0 1 0 0 1')}`
    when 'inverted'
        `#{orientateCmd('inverted', '-1 0 1 0 -1 1 0 0 1')}`
    else
        raise "Don't know how to orientate to #{orientation}"
    end
end


# returns direction of $screen: left, right, normal or invert
def getOrientation()
    if `#{$orientationCmd}` =~ $orientationRE
        return $1 == '' ? 'normal' : $1
    else
        raise "Could not determine orientation of #{$screen} from #{$orientationCmd}"
    end
end


# direction should be +left, +right, flip, left, right, normal, or inverted
def getNewOrientation(direction)
    clockwise = ['normal', 'right', 'inverted', 'left']

    if clockwise.include?(direction)
        return direction
    else
	cur = getOrientation()

        curdir = clockwise.find_index(cur)

	case direction
	when "-left" then return cur == "left" ? "normal" : "left"
	when "-right" then return cur == "right" ? "normal" : "right"
	when "-inverted" then return cur == "inverted" ? "normal" : "inverted"
	else
          shift = case direction
                  when '+left' then -1
                  when '+right' then 1
                  when 'flip' then 2
                  else
                      raise "Unrecognised rotate direction #{direction}"
                  end
       
          newdir = (curdir + shift) % 4

          return clockwise[newdir]
	end
    end
end


# DO
main()


