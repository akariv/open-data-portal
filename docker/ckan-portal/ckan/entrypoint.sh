#!/usr/bin/env bash

source $CKAN_K8S_SECRETS &&\
rm -f $CKAN_CONFIG/*.ini &&\
cp -f $CKAN_K8S_TEMPLATES/${CKAN_WHO_TEMPLATE_PREFIX}who.ini $CKAN_CONFIG/who.ini &&\
bash /templater.sh $CKAN_K8S_TEMPLATES/${CKAN_CONFIG_TEMPLATE_PREFIX}production.ini.template > $CKAN_CONFIG/production.ini &&\
bash /templater.sh $CKAN_K8S_TEMPLATES/${CKAN_INIT_TEMPLATE_PREFIX}ckan_init.sh.template > $CKAN_CONFIG/ckan_init.sh &&\
bash $CKAN_CONFIG/ckan_init.sh
[ "$?" != "0" ] && echo ERROR: CKAN Initialization failed && exit 1

if [ "$*" == "" ]; then
    echo running ckan-paster db init &&\
    ckan-paster --plugin=ckan db init -c "${CKAN_CONFIG}/production.ini" &&\
    echo db initialization complete
    [ "$?" != "0" ] && echo ERROR: DB Initialization failed && exit 1

    echo running ckan_extra_init &&\
    . $CKAN_CONFIG/ckan_extra_init.sh &&\
    echo ckan_extra_init complete
    [ "$?" != "0" ] && echo ERROR: CKAN extra initialization failed && exit 1
    
    exec ${CKAN_VENV}/bin/gunicorn -t 600 --paste ${CKAN_CONFIG}/production.ini --workers ${GUNICORN_WORKERS}
else
    sleep 180
    exec "$@"
fi
