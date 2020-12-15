-- this is a "shared" table, used to avoid circular dependencies
-- functions are added to this table from individual files, where other files can then call them
return {}