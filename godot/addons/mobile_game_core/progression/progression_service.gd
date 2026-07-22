class_name ProgressionService
extends RefCounted

const RANKS := ["Rookie Coil", "Mega Player", "Ultra Player", "Reactor Master", "Coil Commander", "Serpent Elite", "Apex Anaconda", "Golden Legend", "Quantum Serpent", "Infinite Coil"]

static func campaign_rank(completions: int) -> String:
    if completions <= 0: return RANKS[0]
    if completions < RANKS.size(): return RANKS[completions]
    return "Reactor Immortal %s" % _roman(maxi(1, completions - RANKS.size() + 1))

static func _roman(number: int) -> String:
    var result := ""
    var remaining := number
    for pair in [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
        while remaining >= pair[0]:
            result += pair[1]
            remaining -= pair[0]
    return result

