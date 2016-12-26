https://github.com/django/django.git
http://djangobook.py3k.cn/2.0/chapter01/

Installing the development version

Tracking Django development

If you decide to use the latest development version of Django, you’ll want to pay close attention to the development timeline, and you’ll want to keep an eye on the release notes for the upcoming release. This will help you stay on top of any new features you might want to use, as well as any changes you’ll need to make to your code when updating your copy of Django. (For stable releases, any necessary changes are documented in the release notes.)
If you’d like to be able to update your Django code occasionally with the latest bug fixes and improvements, follow these instructions:

Make sure that you have Git installed and that you can run its commands from a shell. (Enter git help at a shell prompt to test this.)

Check out Django’s main development branch like so:

$ git clone git://github.com/django/django.git
This will create a directory django in your current directory.

https://pip.pypa.io/en/stable/installing/#do-i-need-to-install-pip

Make sure that the Python interpreter can load Django’s code. The most convenient way to do this is to use virtualenv, virtualenvwrapper, and pip. The contributing tutorial walks through how to create a virtualenv on Python 3.

After setting up and activating the virtualenv, run the following command:

$ pip install -e django/
This will make Django’s code importable, and will also make the django-admin utility command available. In other words, you’re all set!

When you want to update your copy of the Django source code, just run the command git pull from within the djangodirectory. When you do this, Git will automatically download any changes.


