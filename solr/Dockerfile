FROM solr:8.3 as hyku-solr
ENV SOLR_USER="solr" \
    SOLR_GROUP="solr"
USER root
COPY --chown=solr:solr security.json /var/solr/data/security.json
USER $SOLR_USER
