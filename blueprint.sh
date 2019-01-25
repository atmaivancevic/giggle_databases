#!/bin/bash

# Fri Jan 25

# download blueprint data 
# go to deepblue dashboard, experiments grid page: https://deepblue.mpi-inf.mpg.de/dashboard.php#ajax/deepblue_view_grid.php
# first, download all H3K27ac chipseq bed files
# In Data types, select: Peaks (35075)
# In Projects, select: BLUEPRINT Epigenome (2485)
# In Genome, select: GRCh38 (2485)
# In Epigenetic Marks, select: H3K27ac (401)
# Then at the top left, click 'Select all experiments displayed in the Grid'
# These 401 entries should now appear at the bottom. Click 'Proceed to the download page'
# In the Download Options, got to Metadata, and from the dropdown menu add: Name, Epigenetic_Mark, Biosource, Sample_ID
# At the bottom, click 'Request Download'
# request id r3488283 (https://deepblue.mpi-inf.mpg.de/request.php?_id=r3488283) 
# now we wait..... (usually only takes a few min)
