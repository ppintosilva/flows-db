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

STATUS_DIR		:= .populate_status

FLOWS_5MIN_STATUS	:= 	$(patsubst $(FLOWS_5MIN_DIR)/%.csv, \
						$(STATUS_DIR)/fivemin/%.ok, \
						$(FLOWS_5MIN))

FLOWS_15MIN_STATUS	:= 	$(patsubst $(FLOWS_15MIN_DIR)/%.csv, \
						$(STATUS_DIR)/fifteenmin/%.ok, \
						$(FLOWS_15MIN))

FLOWS_HOUR_STATUS	:= 	$(patsubst $(FLOWS_HOUR_DIR)/%.csv, \
						$(STATUS_DIR)/hourly/%.ok, \
						$(FLOWS_HOUR))

FLOWS_DAY_STATUS	:= 	$(patsubst $(FLOWS_DAY_DIR)/%.csv, \
						$(STATUS_DIR)/daily/%.ok, \
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

$(call check_defined,GOPATH,directory containing the flow data)
$(call check_defined,DATA_DIR,directory containing the flow data)
$(call check_defined,PGUSER,postgres username)
$(call check_defined,PGPASSWORD,postgres password)
$(call check_defined,PGHOST,postgres host)
$(call check_defined,PGPORT,postgres host)
$(call check_defined,PGDATABASE,postgres database name)

$(TIMECOPY_BIN) :

$(STATUS_DIR)/fivemin/%.ok : $(FLOWS_5MIN_DIR)/%.csv
	$(call populate-csv,od_05min)

$(STATUS_DIR)/fifteenmin/%.ok : $(FLOWS_15MIN_DIR)/%.csv
	$(call populate-csv,od_15min)

$(STATUS_DIR)/hourly/%.ok : $(FLOWS_HOUR_DIR)/%.csv
	$(call populate-csv,od_1hour)

$(STATUS_DIR)/daily/%.ok : $(FLOWS_DAY_DIR)/%.csv
	$(call populate-csv,od_24hours)

$(FLOWS_WEEK_STATUS) : $(FLOWS_WEEK)
	$(call populate-csv,od_7days)

populate: $(TIMECOPY_BIN) $(FLOWS_5MIN_STATUS) $(FLOWS_15MIN_STATUS) \
		  $(FLOWS_HOUR_STATUS) $(FLOWS_DAY_STATUS) $(FLOWS_WEEK_STATUS)


# ============================= #
# ============================= #

EXPAND_ROWS_SQL		:= scripts/expand_rows.j2

FLOWS_5MIN_EXSTATUS	:= 	$(STATUS_DIR)/fivemin/.expanded_ok

FLOWS_15MIN_EXSTATUS:= 	$(STATUS_DIR)/fifteenmin/.expanded_ok

FLOWS_HOUR_EXSTATUS	:= 	$(STATUS_DIR)/hourly/.expanded_ok

FLOWS_DAY_EXSTATUS	:= 	$(STATUS_DIR)/daily/.expanded_ok

define expand-db
	printf '{"table":"${1}","frequency":"${2} ${3}"}' | \
	pipenv run j2 -f json ${EXPAND_ROWS_SQL} | \
	xargs -I {} psql -c "{}"
endef

$(FLOWS_5MIN_EXSTATUS) : $(FLOWS_5MIN_STATUS)
	$(call expand-db,od_05min,5,min)

$(FLOWS_15MIN_EXSTATUS) : $(FLOWS_15MIN_STATUS)
	$(call expand-db,od_15min,15,min)

$(FLOWS_HOUR_EXSTATUS) : $(FLOWS_HOUR_STATUS)
	$(call expand-db,od_1hour,1,hour)

$(FLOWS_DAY_EXSTATUS) : $(FLOWS_DAY_STATUS)
	$(call expand-db,od_24hours,1,day)

expand:   $(FLOWS_5MIN_EXSTATUS) $(FLOWS_15MIN_EXSTATUS) \
		  $(FLOWS_HOUR_EXSTATUS) $(FLOWS_DAY_EXSTATUS)
