# Create an auto-incrementing build number.

REV_NUMBER_LDFLAGS  = -Xlinker --defsym -Xlinker __REV_DATE=$$(date +'%Y%m%d')
REV_NUMBER_LDFLAGS += -Xlinker --defsym -Xlinker __REV_NUMBER=$$(cat $(REV_NUMBER_FILE))

# Revision number file.  Increment if any object file changes.
$(REV_NUMBER_FILE): $(OBJECTS)
	@if ! test -f $(REV_NUMBER_FILE); then echo 0 > $(REV_NUMBER_FILE); fi
	@echo $$(($$(cat $(REV_NUMBER_FILE)) + 1)) > $(REV_NUMBER_FILE)
