# Get survey data from Oracle

channel <- gapindex::get_connected()

# survey definition IDs
#ifelse(SRVY == "GOA", 47, 52)

# CPUE - from GAP_PRODUCTS
a <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.CPUE")
write.csv(x = a, "./data/gapproducts_cpue.csv", row.names = FALSE)

# Haul and catch data - from RACEBASE
a <- RODBC::sqlQuery(channel, "SELECT * FROM RACEBASE.CATCH")
write.csv(x = a, "./data/racebase_catch.csv", row.names = FALSE)

print("Finished downloading CATCH")

a <- RODBC::sqlQuery(channel, "SELECT * FROM RACEBASE.HAUL")
a <- RODBC::sqlQuery(
  channel,
  paste0(
    "SELECT ",
    paste0(names(a)[names(a) != "START_TIME"],
           sep = ",", collapse = " "
    ),
    " TO_CHAR(START_TIME,'MM/DD/YYYY HH24:MI:SS') START_TIME  FROM RACEBASE.HAUL"
  )
)

write.csv(x = a, "./data/racebase_haul.csv", row.names = FALSE)

print("Finished downloading HAUL")