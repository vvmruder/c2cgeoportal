.. _developer_server_side:

Server-side development
=======================

Create development environment in a project
-------------------------------------------

c2cgeoportal developers often need to test c2cgeoportal changes in the context
of an existing c2cgeoportal application. Here is how:

Build the new containers:

.. prompt:: bash

    git clone git@github.com:camptocamp/c2cgeoportal.git
    cd c2cgeoportal
    MAJOR_VERSION=${major_version} ./docker-run make build

Than they are ready to use in the application on the same host.

Tests
-----

Running tests
~~~~~~~~~~~~~

To be able to run c2cgeoportal tests you need to have the c2cgeoportal source
code, and a make environment for it. So do that first, as described below.

Install c2cgeoportal from source
................................

Check out c2cgeoportal from GitHub:

.. prompt:: bash

    git clone git@github.com:camptocamp/c2cgeoportal.git
    cd c2cgeoportal

Pull all the base images:

.. prompt:: bash

    ./docker-run make pull

If you modify something in the folder ``docker/build`` build the base image:

.. prompt:: bash

    docker build --tag camptocamp/geomapfish-build-dev:${major_version} docker/build

Build everything:

.. prompt:: bash

    ./docker-run make build

c2cgeoportal has two types of tests: unit tests and functional tests. The unit
tests are self-contained, and do not require any specific setup. The functional
tests require to run with ``docker-compose-run``.

docker-run will:

* Run the given command in the docker build image.
* Mount the current directory in /src.
* Use the current user and home directory.
* Use a named volume related to the current folder in ``/build``.

docker-compose will also:

* Have a testing database and a testing MapServer.

Docker images dependencies::

.. image:: docker.png
.. source file is docker.dia.

Image nomenclature:

* ``camptocamp/geomapfish-*`` for all images generated by/for c2cgeoportal.
* ``camptocamp/geomapfish-test-*`` for all images used only for the CI (not pushed on a Docker repository).
* ``camptocamp/testgeomapfish-*`` for all images used by the CI to
    test applications generated using scaffolds.

Unit tests
..........

Before to run the tests, install and build all dependencies:

.. prompt:: bash

    ./docker-run make prepare-tests

Run the tests:

.. prompt:: bash

    ./docker-compose-run make tests

To run a specific test use the ``-k`` switch. For example:

.. prompt:: bash

    ./docker-compose-run py.tests -k test_catalogue geoportal/tests

Profiling
---------

.. prompt:: bash

   .build/venv/bin/pip install wsgi_lineprof

At the end of the file ``apache/application.wsgi`` add:

.. code:: python

   from wsgi_lineprof.middleware import LineProfilerMiddleware
   from wsgi_lineprof.filters import FilenameFilter, TotalTimeSorter

   filters = [
       FilenameFilter("entry.py"),
       TotalTimeSorter(),
   ]
   application = LineProfilerMiddleware(application, stream=open('/tmp/pro', 'w'), filters=filters)

.. prompt:: bash

   sudo apache2ctl graceful

Do your request(s).

The profile result will be in the file ``/tmp/pro``.


Upgrade dependencies
--------------------

When we start a new version of c2cgeoportal or just before a new development
phase it is a good idea to update the dependencies.

Eggs
~~~~

All the ``c2cgeoportal`` (and ``tilecloud-chain``) dependencies are present in
the ``c2cgeoportal/scaffolds/update/CONST_versions.mako`` file.

To update them you can simply get them from a travis build in the
``./docker-run pip freeze`` task.

Submodules
~~~~~~~~~~

Go to the OpenLayers folder:

.. prompt:: bash

    cd c2cgeoportal/static/lib/openlayers/

Get the new revision of OpenLayers:

.. prompt:: bash

    git fetch
    git checkout release-<version>

Then you can commit it:

.. prompt:: bash

    cd -
    git add c2cgeoportal/static/lib/openlayers/
    git commit -m "update OpenLayers to <version>"


Database
--------

Object model
~~~~~~~~~~~~

.. image:: database.png
.. source file is database.dia.
   export from DIA using the type "PNG (anti-crénelé) (*.png)", set the width to 1000px.

``TreeItem`` and ``TreeGroup`` are abstract (cannot be create) class used to create the tree.

``FullTextSearch`` references a first level ``LayerGroup`` but without any constrains.

it is not visible on this schema, but the ``User`` of a child schema has a link (``parent_role``)
to the ``Role`` of the parent schema.

``metadata`` vs ``functionality``
....................................

Technically the same ``functionality`` can be reused by more than one element.

``functionalities`` are designed to configure and customize various parts of
the application. For instance to change the default basemap when a new theme
is loaded.

To do that in the CGXP application we trigger an event when we load a theme the
new ``functionnalities``.

The ``metadata`` contains attributes that are directly related to the element.
For example the layer disclaimer, ...


Migration
~~~~~~~~~

We use the ``alembic`` module for database migration. ``alembic`` works with a
so-called *migration repository*, which is a simple directory ``/opt/alembic`` in the
docker image. So developers who modify the ``c2cgeoportal`` database schema should add migration scripts.

Add a new script call from the application's root directory:

.. prompt:: bash

    ./docker-compose-run alembic --name=[main|static] revision --message "<Explicit name>"

Or in c2cgeoportal root directory:

.. prompt:: bash

    ./docker-compose-run alembic \
        --config geoportal/tests/functional/alembic.ini --name=[main|static] \
        revision --message "<Explicit name>"

This will generate the migration script in
``commons/c2cgeoportal/commons/alembic/[main|static]/xxx_<Explicite_name>.py``.

To get the project schema use:
``schema = context.get_context().config.get_main_option('schema')``

The scripts should not fail if it is run again. See:
http://alembic.readthedocs.org/en/latest/cookbook.html#conditional-migration-elements

Then customize the migration to suit your needs, test it:

.. prompt:: bash

    ./docker-compose-run alembic upgrade head

More information at:
 * http://alembic.readthedocs.org/en/latest/index.html
 * http://alembic.readthedocs.org/en/latest/tutorial.html#create-a-migration-script
 * http://alembic.readthedocs.org/en/latest/ops.html

Sub domain
----------

All the static resources used sub domains by using the configurations variables:
``subdomain_url_template`` and ``subdomains``.

To be able to use sub domain in a view we should configure the route as this::

    from c2cgeoportal_geoportal.lib import MultiDomainPregenerator
    config.add_route(
        '<name>', '<path>',
        pregenerator=MultiDomainPregenerator())

And use the ``route_url`` with an additional argument ``subdomain``::

    request.route_url('<name>', subdomain='<subdomain>')}",

Code
----

Coding style
~~~~~~~~~~~~

Please read http://www.python.org/dev/peps/pep-0008/.

And run validation:

.. prompt:: bash

    make checks

Dependencies
------------

Major dependencies docs:

* `SQLAlchemy <http://docs.sqlalchemy.org/>`_
* `GeoAlchemy2 <http://geoalchemy-2.readthedocs.org/>`_
* `alembic <http://alembic.readthedocs.org/>`_
* `Pyramid <http://docs.pylonsproject.org/en/latest/docs/pyramid.html>`_
* `Papyrus <http://pypi.python.org/pypi/papyrus>`_
* `MapFish Print <http://mapfish.github.io/mapfish-print-doc/>`_
* `reStructuredText <http://docutils.sourceforge.net/docs/ref/rst/introduction.html>`_
* `Sphinx <http://sphinx.pocoo.org/>`_
