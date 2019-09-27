#!/bin/bash

source common.bash

let G_DEBUG=0
G_DICOMDIR=$(pwd)/dicom
G_AETITLE=CHIPS
let Gb_AETITLE=0
G_QUERYHOST=127.0.0.1
let Gb_QUERYHOST=0
G_QUERYPORT=4242
let Gb_QUERYPORT=0
G_CALLTITLE=ORTHANC
let Gb_CALLTITLE=0
G_INSTITUTION=BCH-chrisdev
G_SYNOPSIS="

  NAME

        PACS_QR.sh 

  SYNOPSIS
  
        PACS_QR.sh                                                      \\
                        [-h <institution>]                              \\
                        [-P <PACSserver>]                               \\
                        [-p <PACSport>]                                 \\
                        [-a <AETitle>]                                  \\
                        [-c <CalledAETitle>]                            \\
                        [-D]                                            \\  
                        [-d <dicomDir>]                                 \\
                        [-C]                                            \\
                        [-Q <px-find.py args>]

  DESC

        PACS_QR.sh is a thin convenience wrapper around a containerized
        call to \"fnndsc/pypx --px-find\"
  ARGS

        -h <institution>
        If specified, assigns some default AETITLE and PACS variables
        appropriate to the <institution>. Valid <institutions> are

            [   
                'Orthanc',
                'BCH', 
                'BCH-chris', 
                'BCH-chrisdev', 
                'BCH-christest', 
                'MGH', 
                'MGH2'
            ]

        [-P <PACSserver>]
        Explicitly set the PACS IP to <PACSserver>.

        [-p <PACSport>]
        Explicitly set the PACS port to <PACSport>.
        
        [-a <AETitle>]
        Explicitly set the AETitle of the client to <AETitle>

        [-c <CalledAETitle>]
        Explicitly set the CalledAETitle to <CalledAETitle>.

        -D
        If specified, volume mount source files into the container for
        debugging.
        
        NOTE: This assumes the script is run from the root github repo
              directory!

        -d <dicomDir>
        Set the <dicomDir> in the host that is mounted into the container.
        
        -C 
        If specified, delete and recreate the <dicomDir> (assuming appropriate
        file system permissions.

        -Q <px-find args>
        This flag captures CLI that are passed to the px-find module.

  EXAMPLE

    QUERY
    PACS_QR.sh -Q \"--PatientID 1234567\"

    Query the PACS on the passed PatientID. Note that the following query terms are
    accepted by px-find (and returned by the PACS in Query mode):

        parameters = {
            'AccessionNumber': '',
            'PatientID': '',                     # PATIENT INFORMATION
            'PatientName': '',
            'PatientBirthDate': '',
            'PatientAge': '',
            'PatientSex': '',
            'StudyDate': '',                     # STUDY INFORMATION
            'StudyDescription': '',
            'StudyInstanceUID': '',
            'Modality': '',
            'ModalitiesInStudy': '',
            'PerformedStationAETitle': '',
            'NumberOfSeriesRelatedInstances': '', # SERIES INFORMATION
            'InstanceNumber': '',
            'SeriesDate': '',
            'SeriesDescription': '',
            'SeriesInstanceUID': '',
            'QueryRetrieveLevel': 'SERIES'
        }

  RETRIEVE
  PACS_QR.sh -Q \"PatientID 1234567 --retrieve --printReport ''\"

"

function institution_set
{
    local INSTITUTION=$1

    case "$INSTITUTION" 
    in
        orthanc)
          G_AETITLE=CHIPS
          G_QUERYHOST=127.0.0.1
          G_QUERYPORT=4242
          G_CALLTITLE=ORTHANC
        ;;
        BCH-chris)
          G_AETITLE=FNNDSC-CHRIS
          G_QUERYHOST=134.174.12.21
          G_QUERYPORT=104
          G_CALLTITLE=CHRIS
        ;;
        BCH-chrisdev)
          G_AETITLE=FNNDSC-CHRISDEV
          G_QUERYHOST=134.174.12.21
          G_QUERYPORT=104
          G_CALLTITLE=CHRIS
        ;;
        BCH-christest)
          G_AETITLE=FNNDSC-CHRISTEST
          G_QUERYHOST=134.174.12.21
          G_QUERYPORT=104
          G_CALLTITLE=CHRIS
        ;;
        MGH)
          G_AETITLE=ELLENGRANT
          G_QUERYHOST=172.16.128.91
          G_QUERYPORT=104
          G_CALLTITLE=SDM1
        ;;
        MGH2)
          G_AETITLE=ELLENGRANT-CH
          G_QUERYHOST=172.16.128.91
          G_QUERYPORT=104
          G_CALLTITLE=SDM1
        ;;
    esac
}

while getopts h:Q:DCd:P:p:a:c: option ; do
    case "$option" 
    in
        Q) ARGS=$OPTARG                 ;;
        C) let Gb_CLEAR=1               ;;
        D) let Gb_DEBUG=1               ;;
        P) QUERYHOST=$OPTARG          
           Gb_QUERYHOST=1               ;;
        p) QUERYPORT=$OPTARG          
           Gb_QUERYPORT=1               ;;
        a) AETITLE=$OPTARG            
           Gb_AETITLE=1                 ;;
        c) CALLTITLE=$OPTARG          
           Gb_CALLTITLE=1               ;;
        h) G_INSTITUTION=$OPTARG
           let Gb_institution=1         ;;
        *) synopsis_show                ;;
    esac
done

institution_set $G_INSTITUTION

if (( Gb_QUERYHOST )) ; then  G_QUERYHOST=$QUERYHOST;  fi
if (( Gb_QUERYPORT )) ; then  G_QUERYPORT=$QUERYPORT;  fi
if (( Gb_AETITLE )) ;   then  G_AETITLE=$AETITLE;      fi
if (( Gb_CALLTITLE )) ; then  G_CALLTITLE=$CALLTITLE;  fi

if (( Gb_CLEAR )) ; then
        printf "%60s" "Removing legacy/existing $G_DICOMDIR... "
        sudo rm -fr $G_DICOMDIR
        printf "[ OK ]\n"
        printf "%60s" "Creating new $G_DICOMDIR... "
        mkdir $G_DICOMDIR
        chmod 777 $G_DICOMDIR
        printf "[ OK ]\n"
fi

DEBUG=""
if (( Gb_DEBUG )) ; then
        DEBUG=" -v $(pwd)/pypx:/usr/local/lib/python3.6/dist-packages/pypx \
                -v $(pwd)/bin/px-echo:/usr/local/bin/px-echo \
                -v $(pwd)/bin/px-find:/usr/local/bin/px-find \
                -v $(pwd)/bin/px-move:/usr/local/bin/px-move \
                -v $(pwd)/bin/px-listen:/usr/local/bin/px-listen "
fi

docker run  --rm -ti                            \
            -p 10402:10402                      \
            -v $G_DICOMDIR:/dicom               \
            $DEBUG                              \
            local/pypx                          \
            --px-find                           \
            --aec $G_CALLTITLE                  \
            --aet $G_AETITLE                    \
            --serverIP $G_QUERYHOST             \
            --serverPort $G_QUERYPORT           \
            --colorize dark                     \
            --printReport tabular               \
            $ARGS