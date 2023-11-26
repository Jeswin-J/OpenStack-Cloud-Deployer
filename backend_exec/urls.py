from . import views
from django.urls import path

urlpatterns = [
    path('execute_script/', views.execute_script, name = 'execute_script'),
    path('execute_compute_script/', views.execute_compute_script, name = 'execute_compute_script'),
    #path('', views.index, name ='index'),
    path('get_compute_count/', views.get_compute_count, name = 'get_compute_count'),
]