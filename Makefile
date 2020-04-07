TIMECOPY_BIN 	:= $(GOPATH)/bin/timescaledb-parallel-copy

FLOWS			:= $(wildcard $(DATA_DIR)/*.csv)

STATUS_DIR		:= .make
FLOWS_STATUS	:= $(patsubst $(DATA_DIR)/%.csv, \
							  $(STATUS_DIR)/%.ok, \
							  $(FLOWS))

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

$(STATUS_DIR) :
	mkdir -p $(STATUS_DIR)

$(TIMECOPY_BIN) :


$(STATUS_DIR)/%.ok : $(DATA_DIR)/%.csv
	$(call populate-csv,${PGTABLE}) && touch $@

# Variables that need to be set when calling makefile (PGTABLE AND DATA_DIR)
# (should not be set globally when calling 'make populate' multiple times)

checks:
	$(call check_defined,GOPATH,directory containing the go binaries)
	$(call check_defined,PGUSER,postgres username)
	$(call check_defined,PGPASSWORD,postgres password)
	$(call check_defined,PGHOST,postgres host)
	$(call check_defined,PGPORT,postgres host)
	$(call check_defined,PGDATABASE,postgres database name)
	$(call check_defined,DATA_DIR,directory containing the flow data csv files)
	$(call check_defined,PGTABLE,postgres table to insert data in)

populate: checks $(STATUS_DIR) $(TIMECOPY_BIN) $(FLOWS_STATUS)

# ============================= #
# ============================= #

all:
	@echo "Nope"

reset:
	rm -rf $(STATUS_DIR)

.PHONY: all populate reset
