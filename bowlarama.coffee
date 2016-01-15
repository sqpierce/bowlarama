# SET-UP
# $ npm install coffee
# $ npm install underscore
# $ npm install strscan
# $ npm install line-reader

# NOTE: use cntl-v to enter multiline mode if executing in coffee console

# via CLI (assumes bowlarama.txt in same directory):
# $ coffee bowlarama.coffee

# must use alternate namespace for underscore lib to avoid clash with node's use of "_"
_u = require 'underscore'
Scanner = require("strscan").StringScanner
assert = require 'assert'

# convenience print function for debugging
p = console.log

# test games with target scores (http://tralvex.com/pub/bowling/BSC.htm):
games =
  '3/400017314217617/1/0': 72 # spares + spare in last frame
  '344380157/0011122509-': 59 # spare + no last ball
  '4444819/5390x036318-': 91 # spare + strike + no last ball
  '608/420152548/5022x4/' : 87 # strike followed by spare in last frame
  '9/1861438070526/909/3' : 97 # spare in the last frame
  '080541438/0/4570726/x' : 94 # spare and a strike in the last frame
  '219/xxx8/44411507-': 141 # multiple strikes + no last ball
  '411190210408700/xx11': 91 # strike in last frame
  '22x423636605313xxxx' : 122 # multiple strikes in last frame
    
# HELPER FUNCTIONS

frame_score = (f) -> # good for individual frames as well as the bonus
  if /-/.test f # no last ball case
    0
  else if /\//.test f # spare case
    10
  else # parse string as nums with 'x' being 10 (note: this will cover the 'xx' case for bonus)
    # note: "if - then - else" is the tenary operator in coffeescript
    _u.reduce _u.map(f.split(''), (x) -> if x=='x' then 10 else +x), ((memo, num) -> memo += num), 0

get_first = (cntxt, increment) -> # function for use in special cases where we only want to look at first throw of frame
  ball = _u.first cntxt.array[cntxt.idx+increment].split('')
  if ball == 'x' then 10 else +ball

# function which increments score based on current frame and context
full_score = (total_score,frame) ->
  score = frame_score frame
  if @.idx <= 8 # look aheads for spares and strikes, only if we're in first nine frames
    # SPARE: add look ahead by one
    if /\d\//.test frame
      spare_lookahead = get_first @, 1 # pass context and increment amount
      #p "doing lookahead for spare: #{spare_lookahead}"
      score += spare_lookahead
    # STRIKE: add look ahead of whole next frame, unless it's a strike, then we need to look further
    else if /x/.test frame
      f = @.array[@.idx+1]
      lookahead_one = frame_score f
      # function we can execute if we need it for 2nd lookahead, in the case of another strike
      lookahead_two = (cntxt) -> get_first cntxt, 2 #if cntxt.idx == 8 then 0 else get_first cntxt, 2
      strike_lookahead = if /x/.test f then lookahead_one + lookahead_two(@) else lookahead_one
      #p "doing lookahead for strike: #{strike_lookahead}"
      score += strike_lookahead
  @.idx++ # increment the index
  total_score += score # add the score for this frame
  #p "frame: #{@.idx} score: #{score} total score: #{total_score}"
  total_score

# patterns for scanner
frame_patt = /(\d{2}|\d\/|x)/ # two digits, spare, or strike
bonus_patt = /.+/ # bonus is whatever's left

# MAIN ITERATOR
# loop through our test games and check results

get_game_score = (game) ->
  scanner = new Scanner game
  frames = []
  _u.each (_u.range 10), (index) -> # get the first 10 frames, not counting bonus
    frames[index] = scanner.scan frame_patt
  frames.push scanner.scan bonus_patt # get the bonus
  #p frames

  # context object to store index position in array, as well as the array itself
  # (for backward and forward-looking in case of spares and strikes)
  context =
    idx: 0
    array: frames
    
  # reduce function interates over array and calculates score using "full_score" function (meaning frame + bonuses)
  _u.reduce frames, full_score, 0, context

_u.each (_u.pairs games), (game) ->
  # get characters as array
  #p _u.first game

  result = get_game_score (_u.first game)
  
  # test against our target scores
  p "result: #{result} == #{_u.last game}"
  assert.equal result, _u.last game

# test above is good, on to reading file

total = 0
count = 0

require('line-reader').eachLine 'bowlarama.txt', (line, last) ->
    result = get_game_score line
    total += result
    count++
    #p count, line, result, total
    if last
      mean = (total / count).toFixed(2)
      p "count: #{count} total: #{total} mean: #{mean}"








