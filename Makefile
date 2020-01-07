TIMECOPY_BIN 	:= $(GOPATH)/bin/timescaledb-parallel-copy

FLOWS_DIR		:= $(DATA_DIR)/flows
FLOWS_5MIN_DIR  := $(FLOWS_DIR)/fivemin
FLOWS_15MIN_DIR	:= $(FLOWS_DIR)/fifteenmin
FLOWS_HOUR_DIR	:= $(FLOWS_DIR)/hourly
FLOWS_DAY_DIR	:= $(FLOWS_DIR)/daily
FLOWS_WEEK_DIR	:= $(FLOWS_DIR)/weekly

FLOWS_5MIN		:= $(wildcard $(FLOWS_5MIN_DIR)/*.csv)
FLOWS_15MIN		:= $(wildcard $(FLOWS_15MIN_DIR)/*.csv)
FLOWS_HOUR		:= $(wildcard $(FLOWS_HOUR_DIR)/*.csv)
FLOWS_DAY		:= $(wildcard $(FLOWS_DAY_DIR)/*.csv)
FLOWS_WEEK		:= $(FLOWS_WEEK_DIR)/weekly_flows.csv

STATUS_DIR		:= .make

FLOWS_5MIN_STATUS	:= 	$(patsubst $(FLOWS_5MIN_DIR)/%.csv, \
						$(STATUS_DIR)/%.ok, \
						$(FLOWS_5MIN))

FLOWS_15MIN_STATUS	:= 	$(patsubst $(FLOWS_15MIN_DIR)/%.csv, \
						$(STATUS_DIR)/%.ok, \
						$(FLOWS_15MIN))

FLOWS_HOUR_STATUS	:= 	$(patsubst $(FLOWS_HOUR_DIR)/%.csv, \
						$(STATUS_DIR)/%.ok, \
						$(FLOWS_HOUR))

FLOWS_DAY_STATUS	:= 	$(patsubst $(FLOWS_DAY_DIR)/%.csv, \
						$(STATUS_DIR)/%.ok, \
						$(FLOWS_DAY))

FLOWS_WEEK_STATUS	:= $(STATUS_DIR)/weekly_flows.ok

CONNECTION_STRING	:= "host=$(PGHOST) port=$(PGPORT) user=$(PGUSER) password=$(PGPASSWORD) sslmode=disable"

FLAGS_COPY	:= \
--workers 2 \
--reporting-period 10s \
--connection $(CONNECTION_STRING) \
--skip-header \
--db-name $(PGDATABASE)

# ============================= #
# ============================= #

define populate-csv
	$(TIMECOPY_BIN) \
	$(FLAGS_COPY) \
	--table ${1} \
	--file $^
endef

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

# ============================= #
# ============================= #

$(call check_defined,GOPATH,directory containing the go binaries)
$(call check_defined,DATA_DIR,directory containing the flow data)
$(call check_defined,PGUSER,postgres username)
$(call check_defined,PGPASSWORD,postgres password)
$(call check_defined,PGHOST,postgres host)
$(call check_defined,PGPORT,postgres host)
$(call check_defined,PGDATABASE,postgres database name)

$(STATUS_DIR) :
	mkdir -p $(STATUS_DIR)

$(TIMECOPY_BIN) :

$(STATUS_DIR)/%.ok : $(FLOWS_5MIN_DIR)/%.csv
	$(call populate-csv,od_05min) && touch $@

$(STATUS_DIR)/%.ok : $(FLOWS_15MIN_DIR)/%.csv
	$(call populate-csv,od_15min) && touch $@

$(STATUS_DIR)/%.ok : $(FLOWS_HOUR_DIR)/%.csv
	$(call populate-csv,od_1hour) && touch $@

$(STATUS_DIR)/%.ok : $(FLOWS_DAY_DIR)/%.csv
	$(call populate-csv,od_24hours) && touch $@

$(FLOWS_WEEK_STATUS) : $(FLOWS_WEEK)
	$(call populate-csv,od_7days)

populate: $(STATUS_DIR) \
		  $(TIMECOPY_BIN) $(FLOWS_5MIN_STATUS) $(FLOWS_15MIN_STATUS) \
		  $(FLOWS_HOUR_STATUS) $(FLOWS_DAY_STATUS) $(FLOWS_WEEK_STATUS)


# ============================= #
# ============================= #

PSQL_FLAGS := -v "ON_ERROR_STOP=1"

AGG_1	:=	$(STATUS_DIR)/agg_hour_weekday.ok

AGG_2	:= 	$(STATUS_DIR)/agg_05min_weekdaycat.ok

AGG_3	:= 	$(STATUS_DIR)/agg_15min_weekdaycat.ok

$(AGG_1) : $(FLOWS_HOUR_STATUS)
	psql $(PSQL_FLAGS) -f scripts/agg_hour_weekday.sql && touch $@

$(AGG_2) : $(FLOWS_5MIN_STATUS)
	psql $(PSQL_FLAGS) -f scripts/agg_05min_weekdaycat.sql && touch $@

$(AGG_3) : $(FLOWS_15MIN_STATUS)
	psql $(PSQL_FLAGS) -f scripts/agg_15min_weekdaycat.sql && touch $@

aggregate: $(AGG_1) $(AGG_2) $(AGG_3)

# ============================= #
# ============================= #


all:
	@echo "Nope"

reset:
	rm -rf $(STATUS_DIR)

.PHONY: all populate expand reset
