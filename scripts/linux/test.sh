#!/bin/bash

###############################################################################
#
# Usage: test.sh [genx]
# 
# Test script for all OSSIM repositories. The test data referenced must be 
# available at $OSSIM_BATCH_TEST_DATA, which must be defined prior.
#
# The expected results should be in $OSSIM_BATCH_TEST_RESULTS. This environment 
# variable can be predefined, otherise, will default to:
#
#    $OSSIM_BATCH_TEST_DATA/ossim-test-results
#
# If the optional "genx" argument is specified, then expected results will be
# generated at $OSSIM_BATCH_TEST_RESULTS ONLY IF this directory is not present.
# If $OSSIM_BATCH_TEST_RESULTS exists, no expected results will be generated.
#
###############################################################################
#set -x; trap read debug

GENERATE_EXPECTED_RESULTS=0
if [ ! -z $1 ] && [ $1 == "genx" ]; then
  GENERATE_EXPECTED_RESULTS=1
  echo; echo "STATUS: Generating expected results..."; echo
fi

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ -z $OSSIM_BUILD_DIR ]; then
  pushd $SCRIPT_DIR/../../../build
  OSSIM_BUILD_DIR=$PWD
  #echo "#### DEBUG #### OSSIM_BUILD_DIR=$OSSIM_BUILD_DIR"
  popd
  export OSSIM_BUILD_DIR
fi

if [ -z $OSSIM_BATCH_TEST_DATA ]; then
  echo "ERROR: Required env var OSSIM_BATCH_TEST_DATA is not defined. Aborting setup..."; 
  exit 1
fi

if [ -z $OSSIM_BATCH_TEST_RESULTS ]; then
  export OSSIM_BATCH_TEST_RESULTS=$OSSIM_BATCH_TEST_DATA/ossim-test-results
fi

#echo "#### DEBUG #### OSSIM_BUILD_DIR=$OSSIM_BUILD_DIR"
#echo "#### DEBUG #### OSSIM_BATCH_TEST_DATA=$OSSIM_BATCH_TEST_DATA"
#echo "#### DEBUG #### OSSIM_BATCH_TEST_RESULTS=$OSSIM_BATCH_TEST_RESULTS"

#export the OSSIM runtime env to child processes:
export PATH=$OSSIM_BUILD_DIR/bin:$PATH
export LD_LIBRARY_PATH=$OSSIM_BUILD_DIR/lib:$LD_LIBRARY_PATH

# TEST 1: Check ossim-info version:
echo; echo "STATUS: Running ossim-info test...";
COUNT=`ossim-info --version | grep --count "ossim-info 1.9"`
if [ $COUNT != "1" ]; then
  echo "FAIL: Failed ossim-info test"; exit 1
else
  echo "STATUS: Passed ossim-info test"
fi


if [ $GENERATE_EXPECTED_RESULTS -eq 1 ] && [ ! -e $OSSIM_BATCH_TEST_RESULTS ]; then

  # Check if expected results are present, generate if not:
  echo; echo "STATUS: No expected results detected, generating new expected results in <$OSSIM_BATCH_TEST_RESULTS>..."
  mkdir $OSSIM_BATCH_TEST_RESULTS
  if [ $? -ne 0 ]; then
    echo; echo "ERROR: Failed while attempting to create results directory at <$OSSIM_BATCH_TEST_RESULTS>. Check permissions."
    echo 1
  fi
  pushd $SCRIPT_DIR/../../test/scripts
  ossim-batch-test --accept-test all super-test.kwl
  popd
  #echo "STATUS: ossim-batch-test exit code = $?";echo
  if [ $? != 0 ]; then
    echo "FAIL: Error encountered generating expected results."
    exit 1
  else
    echo "STATUS: Successfully generated expected results."; echo
  fi

else

  # Run batch tests
  echo; echo "STATUS: Running batch tests..."
  pushd $SCRIPT_DIR/../../test/scripts
  ossim-batch-test super-test.kwl
  EXIT_CODE=$?
  popd
  #echo "#### DEBUG #### EXIT_CODE = $EXIT_CODE"
  if [ $EXIT_CODE != 0 ]; then
    echo "FAIL: Failed batch test"
    exit 1
  else
    echo "STATUS: Passed batch test"
  fi

fi


# Success!
echo "STATUS: Passed all tests."
exit 0

