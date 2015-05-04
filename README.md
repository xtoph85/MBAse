#MBAse

MBAse (read: m-base) is a management system for multilevel bbusiness artifacts [1].

##Prerequisites
The multilevel business artifact database works in conjunction with an XML database management system.
Download and install an XML database management system.

We recommend BaseX 8.1.1: http://basex.org/

MBAse requires the SCXML-XQ module [2] to be available in the XML database management system's repository.
Follow the instructions for SCXML-XQ first.

##Installation
Checkout the repository and run the .bxs script in order to install the module.
Open the shell, change to the root directory of the repository and run the following command:

basex repo_install.bxs

##References

[1] Christoph Schütz, Lois M. L. Delcambre and Michael Schrefl:
    Multilevel Business Artifacts.
    M. La Rosa and P. Soffer (Eds.): BPM 2012 Workshops, LNBIP 132, pp. 304–315, 2013. 

[2] SCXML-XQ: https://github.com/xtoph85/SCXML-XQ
