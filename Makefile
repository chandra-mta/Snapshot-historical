############################
# Change the task name!
############################
TASK = Snapshot

include /data/mta4/MTA/include/Makefile.MTA

BIN  = force_scs107_alert.pl run-acorn.pl run-multimon.pl snarcl.pl tlogr.pl
IDL_BIN  = snap_plot.pro snap_plot_ctx.pro snap_plot_iru.pro snap_plot_mom.pro
CGI_BIN  = snap.cgi
DATA = chandra-msids.list snaps2.par snaps2_alerts.par snaps2_noalerts.par
DOC  = ReadMe
PERLLIB = check_state.pm check_state_alerts.pm check_state_force_alert.pm check_state_noalerts.pm comps.pm snap.pm snap_format.pm
WWW  = snapshot_hlp.html

install:
ifdef BIN
	rsync --times --cvs-exclude $(BIN) $(INSTALL_BIN)/
endif
ifdef DATA
	mkdir -p $(INSTALL_DATA)
	rsync --times --cvs-exclude $(DATA) $(INSTALL_DATA)/
endif
ifdef DOC
	mkdir -p $(INSTALL_DOC)
	rsync --times --cvs-exclude $(DOC) $(INSTALL_DOC)/
endif
ifdef IDL_BIN
	mkdir -p $(INSTALL_IDL_BIN)
	rsync --times --cvs-exclude $(IDL_BIN) $(INSTALL_IDL_BIN)/
endif
ifdef CGI_BIN
	mkdir -p $(INSTALL_CGI_BIN)
	rsync --times --cvs-exclude $(CGI_BIN) $(INSTALL_CGI_BIN)/
endif
ifdef PERLLIB
	mkdir -p $(INSTALL_PERLLIB)
	rsync --times --cvs-exclude $(PERLLIB) $(INSTALL_PERLLIB)/
endif
ifdef WWW
	mkdir -p $(INSTALL_WWW)
	rsync --times --cvs-exclude $(WWW) $(INSTALL_WWW)/
endif
