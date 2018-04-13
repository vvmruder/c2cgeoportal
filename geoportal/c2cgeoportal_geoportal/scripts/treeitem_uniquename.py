# -*- coding: utf-8 -*-

# Copyright (c) 2014-2018, Camptocamp SA
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# The views and conclusions contained in the software and documentation are those
# of the authors and should not be interpreted as representing official policies,
# either expressed or implied, of the FreeBSD Project.


import argparse
import transaction
from pyramid.paster import get_app
from logging.config import fileConfig
import os


def main():
    parser = argparse.ArgumentParser(
        description="This script will rename all the theme elements to removes duplicated elements."
    )
    parser.add_argument(
        '-i', '--iniconfig',
        default='geoportal/production.ini',
        help='project .ini config file',
    )
    parser.add_argument(
        '-n', '--app-name',
        default="app",
        help='The application name (optional, default is "app")',
    )

    options = parser.parse_args()

    # Read the configuration
    env = {}
    env.update(os.environ)
    env["LOG_LEVEL"] = "INFO"
    env["GUNICORN_ACCESS_LOG_LEVEL"] = "INFO"
    env["C2CGEOPORTAL_LOG_LEVEL"] = "WARN"
    fileConfig(options.iniconfig, defaults=env)
    get_app(options.iniconfig, options.app_name, options=env)

    from c2cgeoportal_commons.models import DBSession
    from c2cgeoportal_commons.models.main import LayerV1, LayerWMS, LayerWMTS, LayerGroup, Theme

    for class_ in [LayerV1, LayerWMS, LayerWMTS, LayerGroup, Theme]:
        names = []
        for item in DBSession.query(class_).all():
            if item.name in names:
                i = 2
                while "{}-{}".format(item.name, i) in names:
                    i += 1

                item.name = "{}-{}".format(item.name, i)
            names.append(item.name)

    transaction.commit()
