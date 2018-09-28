# Generic Makefile Project

## License
This Makefile is under Apache License. See file 'LICENSE' for details.
## Files list
**Makefile** : Makefile documented to use for your projects.

**README.md** : This file

**rev-number.txt** : Contains a revision number, incremented with each new compilation.

**LICENSE** : Contains the text of the Apache license.

**filter_cmd.sh** : Private script used by Doxygen.

**makefile.doxyfile** : Doxygen configuration file

**revnumber.mak** : Contains revision number rules. Called by the Makefile

## Documentation
You can generate documentation with doxygen. Just type :
> doxygen makefile.doxyfile

The documentation will be generated in the 'dox' directory, in HTML and Latex format. You can generate a PDF by going into the 'dox / latex' directory, then typing :
> make pdf

## Makefile adaptation for your projects
Copy the files 'Makefile' et 'revnumber.mak' to the root directory of your project.
In the 'Makefile', you must modify the variables of the 'Project Variables' area and possibly those of the 'Build variables' area. It is easier for this last field to be modified by an external definition of the variables when you use an IDE. This will be able to generate the variables according to your build configuration.
