#! /bin/bash
# -*- encoding: utf-8 -*-
#
# This script modifies the makefile so that doxygen can process it.

# Read the file, remplacing the '##' start line to '//!'
COMM=`sed -e 's|^##|//!|' ${1}`

# Replaces variable assignments with the #include directive,
# commenting on all lines not yet commented,
# then modifying the bash comments ("# ") into
# C comments ("//").
echo "${COMM}" | sed -r 's|^([a-zA-Z_0-9\-]*) *[?:+]?=.*|#define \1|' \
               | sed -e 's|^[^#/]|//|' \
               | sed -e 's|^# |//|'

