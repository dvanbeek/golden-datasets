.PHONY: all clean test download
#.ONESHELL:

SHELL	= /bin/bash
WGET	= wget
MKDIR_P	= mkdir -p
RM_RF	= rm -rf
EMPTY	=

BEDTOOLS_URL 		= https://github.com/arq5x/bedtools2/releases/download/v2.29.2/bedtools.static.binary
DATA_DIR			= data
DATASETS_TSV		= $(DATA_DIR)/datasets.tsv
DATASETS_TEST_TSV	= $(DATA_DIR)/datasets.test.tsv

DEFAULT_DIR			= $(DATA_DIR) # Change this line if you want to change the default directory
#TODO: Dynamic set doesn't work correctly
# INSTALL_INPUT	:= $(realpath $(shell read -p "Enter path to installation directory [build]:"$$'\n' && echo $$REPLY))
INSTALL_DIR			?= $(or $(INSTALL_INPUT), $(strip $(DEFAULT_DIR)))
TEST_DIR			:= $(INSTALL_DIR)/test

DATASETS_URLS		:= $(shell awk 'NR>1 {print $$2}' $(DATASETS_TSV))
DATASETS_TEST_URLS	:= $(shell awk 'NR>1 {print $$2}' $(DATASETS_TEST_TSV))
DATASETS_TAGS 		:= $(join $(addsuffix /,$(shell awk 'NR>1 {print $$1}' $(DATASETS_TSV))), $(notdir $(DATASETS_URLS)))
DATASETS_TEST_TAGS 	:= $(join $(addsuffix /,$(shell awk 'NR>1 {print $$1}' $(DATASETS_TEST_TSV))), $(notdir $(DATASETS_TEST_URLS)))
DATASETS_FILES		:= $(addprefix $(INSTALL_DIR)/, $(DATASETS_TAGS))
DATASETS_TEST_FILES	:= $(addprefix $(TEST_DIR)/, $(DATASETS_TEST_TAGS))

BAM_FILES			:= $(filter %.bam,$(DATASETS_FILES))
BAI_FILES			:= $(filter %.bai,$(DATASETS_FILES))
FASTQ_FILES			:= $(filter %.fastq,$(DATASETS_FILES))
BAM2FASTQ_FILES		:= $(BAM_FILES:.bam=.fastq)

URL_FILES			:= $(addsuffix .url, $(DATASETS_FILES))
URL_TEST_FILES		:= $(addsuffix .url, $(DATASETS_TEST_FILES))


###############################################################################
# 								DOWNLOAD
###############################################################################

$(INSTALL_DIR)/%.url: 
	$(MKDIR_P) $(@D) && awk '/$(notdir $(basename $*))/ {print $$2}' $< > $@

$(URL_TEST_FILES): $(INSTALL_DIR)/test/%.url: $(DATASETS_TEST_TSV)
$(URL_FILES): $(INSTALL_DIR)/%.url: $(DATASETS_TSV)


$(INSTALL_DIR)/%.bam $(INSTALL_DIR)/%.bai:
	$(WGET) -O $@ $(shell cat $(word 1, $|))

$(filter %.bam %.bai, $(DATASETS_TEST_FILES)): $(INSTALL_DIR)/test/%: | $(INSTALL_DIR)/test/%.url
$(filter %.bam %.bai, $(DATASETS_FILES)): $(INSTALL_DIR)/%: | $(INSTALL_DIR)/%.url

# TODO: Check file hash

# 2. BAM 2 FASTQ BAM FILES
bedtools:
	@echo "Install bedtools requirement"
	@wget $(BEDTOOLS_URL);
	@mv bedtools.static.binary bedtools;
	@chmod a+x bedtools


%.bam: %.fastq | bedtools
	bedtools bamtofastq -i $@ -fq $(word 1, $<)


###############################################################################
# 								PHONY
###############################################################################

download: $(DATASETS_FILES)

test: $(DATASETS_TEST_FILES)

all:

clean:
	$(RM_RF) $(URL_FILES)
	$(RM_RF) $(URL_TEST_FILES)
	$(RM_RF) $(DATASETS_TEST_FILES)
	$(RM_RF) $(DATASETS_FILES) 
	$(RM_RF) $(TEST_DIR)
	$(RM_RF) $(shell uniq "$(suffix $(DATASETS_FILES))")