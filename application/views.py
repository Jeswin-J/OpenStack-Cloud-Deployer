from django.shortcuts import render
from application import urls


# Create your views here.
def index(request):
    return render(request, 'index.html')


        