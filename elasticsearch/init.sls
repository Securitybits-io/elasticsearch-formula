#Package.elasticsearch init.sls
{% set elasticsearch = pillar['elasticsearch'] %}

add_elasticsearch_repo:
  pkgrepo.managed:
    - humanname: Elasticsearch Repo {{ elasticsearch['repo'] }}
    - name: deb https://artifacts.elastic.co/packages/{{ elasticsearch['repo'] }}/apt stable main
    - file: /etc/apt/sources.list.d/elasticsearch.list
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch

install_elasticsearch:
  pkg.installed:
    - name: elasticsearch
    - version: {{ elasticsearch['version'] }}
    - hold: {{ elasticsearch['hold'] | default(False) }}
    - require:
      - pkgrepo: add_elasticsearch_repo

{% if salt['pillar.get']('elasticsearch:config') %}
/etc/elasticsearch/elasticsearch.yml:
  file.serialize:
    - dataset_pillar: elasticsearch:config
    - formatter: yaml
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: install_elasticsearch
{% endif %}

{% if salt['pillar.get']('elasticsearch:jvm') %}
/etc/elasticsearch/jvm.options:
  file.managed:
    - source: salt://elasticsearch-formula/etc/elasticsearch/jvm.options
    - template: jinja
    - user: root
    - group: elasticsearch
    - mode: 660
    - require:
      - pkg: install_elasticsearch
{% endif %}

elasticsearch:
  service.running:
    - restart: {{ elasticsearch['restart'] | default(True) }}
    - enable: {{ elasticsearch['enable'] | default(True) }}
    - require:
      - pkg: install_elasticsearch
    - watch:
      {% if salt['pillar.get']('elasticsearch:config') %}
      - file: /etc/elasticsearch/elasticsearch.yml
      {% endif %}
      {% if salt['pillar.get']('elasticsearch:jvm') %}
      - file: /etc/elasticsearch/jvm.options
      {% endif %}
      - pkg: elasticsearch
