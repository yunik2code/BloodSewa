from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User

class CustomUserAdmin(UserAdmin):
    # Fields to display in list view
    list_display = ('username', 'email', 'blood_group', 'phone', 'is_donor', 'is_staff')

    # Fields to filter by in admin
    list_filter = ('blood_group', 'is_donor', 'is_staff')

    # Fields to show on the edit page
    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        ('Personal Info', {'fields': ('email', 'phone', 'blood_group', 'latitude', 'longitude', 'is_donor')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )

    # Fields to show on the “Add User” page
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('username', 'email', 'phone', 'blood_group', 'latitude', 'longitude', 'is_donor', 'password1', 'password2'),
        }),
    )

    search_fields = ('username', 'email', 'blood_group', 'phone')
    ordering = ('username',)

admin.site.register(User, CustomUserAdmin)
