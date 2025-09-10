from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import RegexValidator
from django.contrib.auth.hashers import make_password, check_password

BLOOD_GROUPS = [
    ('A+', 'A+'), ('A-', 'A-'),
    ('B+', 'B+'), ('B-', 'B-'),
    ('AB+', 'AB+'), ('AB-', 'AB-'),
    ('O+', 'O+'), ('O-', 'O-'),
]

class User(AbstractUser):
    phone = models.CharField(max_length=15, unique=True)
    blood_group = models.CharField(max_length=3, choices=BLOOD_GROUPS)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    is_donor = models.BooleanField(default=False)
    
    # PIN field with validation for exactly 4 digits
    pin = models.CharField(
        max_length=128,  # Space for hashed PIN
        validators=[RegexValidator(r'^\d{4}$', 'PIN must be exactly 4 digits')],
        help_text="4-digit PIN for authentication"
    )
    
    # Override password field to make it optional/unused
    password = models.CharField(max_length=128, blank=True, null=True)

    def set_pin(self, raw_pin):
        """Hash and set the PIN"""
        if not raw_pin or len(raw_pin) != 4 or not raw_pin.isdigit():
            raise ValueError("PIN must be exactly 4 digits")
        
        # Prevent common/weak PINs
        weak_pins = ['0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999', 
                    '1234', '4321', '1122', '2211', '0123', '3210']
        if raw_pin in weak_pins:
            raise ValueError("PIN is too common. Please choose a different PIN.")
            
        self.pin = make_password(raw_pin)

    def check_pin(self, raw_pin):
        """Check if the provided PIN matches the stored hashed PIN"""
        return check_password(raw_pin, self.pin)

    def __str__(self):
        return f"{self.username} ({self.blood_group})"