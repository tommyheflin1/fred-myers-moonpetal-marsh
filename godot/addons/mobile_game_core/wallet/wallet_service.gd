class_name WalletService
extends RefCounted

signal balance_changed(balance: int, reason: String)
var balance: int = 0
var _processed: Dictionary = {}

func transact(transaction_id: String, amount: int, reason: String) -> bool:
    if transaction_id.is_empty() or _processed.has(transaction_id): return false
    if balance + amount < 0: return false
    _processed[transaction_id] = true
    balance += amount
    balance_changed.emit(balance, reason)
    return true

