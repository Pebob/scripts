--interaction-trigger.lua
--author expwnent
--triggers scripts when a unit does a unit interaction on another

local eventful = require 'plugins.eventful'
local utils = require 'utils'
eventful.enableEvent(eventful.eventType.INTERACTION,1) --cheap, so every tick is fine

attackStrTriggers = attackStrTriggers or {}
defendStrTriggers = defendStrTriggers or {}

local function processTrigger(args)
 local command = {}
 for _,arg in ipairs(args.command) do
  if arg == '\\ATTACK_VERB' then
   table.insert(command,args.attackVerb)
  elseif arg == '\\DEFEND_VERB' then
   table.insert(command,args.defendVerb)
  elseif arg == '\\ATTACKER_ID' then
   table.insert(command,args.attackerId)
  elseif arg == '\\DEFENDER_ID' then
   table.insert(command,args.defenderId)
  elseif arg == '\\ATTACK_REPORT' then
   table.insert(command,args.attackReport)
  elseif arg == '\\DEFEND_REPORT' then
   table.insert(command,args.defendReport)
  elseif string.sub(arg,1,1) == '\\' then
   table.insert(command,string.sub(arg,2))
  else
   table.insert(command,arg)
  end
 end
 dfhack.run_command(table.unpack(command))
end

eventful.onInteraction.interactionTrigger = function(attackVerb, defendVerb, attacker, defender, attackReport, defendReport)
 local extras = {}
 extras.attackVerb = attackVerb
 extras.defendVerb = defendVerb
 extras.attackReport = attackReport
 extras.defendReport = defendReport
 extras.attackerId = attacker
 extras.defenderId = defender
 local suppressAttack = false
 local suppressDefend = false
 for _,trigger in ipairs(attackStrTriggers[attackVerb] or {}) do
  suppressAttack = suppressAttack or trigger.suppressAttack
  suppressDefend = suppressDefend or trigger.suppressDefend
  utils.fillTable(trigger,extras)
  processTrigger(trigger)
  utils.unfillTable(trigger,extras)
 end
 for _,trigger in ipairs(defendStrTriggers[defendVerb] or {}) do
  suppressAttack = suppressAttack or trigger.suppressAttack
  suppressDefend = suppressDefend or trigger.suppressDefend
  utils.fillTable(trigger,extras)
  processTrigger(trigger)
  utils.unfillTable(trigger,extras)
 end

 local eraseReport = function(unit,report)
  for i,v in ipairs(unit.reports.log.Combat) do
   if v == report then
    unit.reports.log.Combat:erase(i)
    break
   end
  end
 end
 if suppressAttack or suppressDefend then
  attacker = df.unit.find(tonumber(attacker))
  defender = df.unit.find(tonumber(defender))
 end
 if suppressAttack then
  eraseReport(attacker,attackReport)
  eraseReport(defender,attackReport)
 end
 if suppressDefend then
  eraseReport(attacker,defendReport)
  eraseReport(defender,defendReport)
 end
end

----------------------------------------------------
--argument processing

validArgs = validArgs or utils.invert({
 'clear',
 'help',
 'onAttackStr',
 'onDefendStr',
 'command',
 'suppressAttack',
 'suppressDefend',
})

local args = utils.processArgs({...}, validArgs)

if args.clear then
 attackStrTriggers = {}
 defendStrTriggers = {}
end

if args.help then
 --print help string
 return
end

if not args.command then
 return
end

if args.onAttackStr then
 if not attackStrTriggers[args.onAttackStr] then
  attackStrTriggers[args.onAttackStr] = {}
 end
 table.insert(attackStrTriggers[args.onAttackStr], args)
end

if args.onDefendStr then
 if not defendStrTriggers[args.onDefendStr] then
  defendStrTriggers[args.onDefendStr] = {}
 end
 table.insert(defendStrTriggers[args.onDefendStr], args)
end

