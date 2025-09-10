from rest_framework import serializers
from django.contrib.auth import get_user_model, authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.exceptions import ValidationError as DjangoValidationError

User = get_user_model()

class RegisterSerializer(serializers.ModelSerializer):
    pin = serializers.CharField(write_only=True, min_length=4, max_length=4)
    confirm_pin = serializers.CharField(write_only=True, min_length=4, max_length=4)
    token = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 
            'phone', 'pin', 'confirm_pin', 'blood_group', 'latitude', 
            'longitude', 'is_donor', 'token'
        ]
    
    def validate_pin(self, value):
        """Validate PIN format"""
        if not value.isdigit():
            raise serializers.ValidationError("PIN must contain only digits.")
        
        # Check for weak/common PINs
        weak_pins = ['0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999', 
                    '1234', '4321', '1122', '2211', '0123', '3210']
        if value in weak_pins:
            raise serializers.ValidationError("PIN is too common. Please choose a different PIN.")
        
        return value
    
    def validate(self, attrs):
        """Validate that PINs match"""
        pin = attrs.get('pin')
        confirm_pin = attrs.get('confirm_pin')
        
        if pin != confirm_pin:
            raise serializers.ValidationError({"confirm_pin": "PINs do not match."})
        
        return attrs
    
    def get_token(self, obj):
        refresh = RefreshToken.for_user(obj)
        return {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }
    
    def create(self, validated_data):
        # Remove confirm_pin from validated_data
        confirmed_pin = validated_data.pop('confirm_pin')
        pin = validated_data.pop('pin')
        
        # Create user without PIN first
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            phone=validated_data['phone'],
            blood_group=validated_data['blood_group'],
            latitude=validated_data.get('latitude'),
            longitude=validated_data.get('longitude'),
            is_donor=validated_data.get('is_donor', False),
        )
        
        # Set PIN using the custom method
        try:
            user.set_pin(pin)
            user.save()
        except ValueError as e:
            user.delete()  # Clean up if PIN setting fails
            raise serializers.ValidationError({"pin": str(e)})
        
        return user

class PhoneLoginSerializer(serializers.Serializer):
    phone = serializers.CharField()
    pin = serializers.CharField(write_only=True, min_length=4, max_length=4)
    
    def validate_pin(self, value):
        """Validate PIN format"""
        if not value.isdigit():
            raise serializers.ValidationError("PIN must be exactly 4 digits.")
        return value
    
    def validate(self, attrs):
        phone = attrs.get('phone')
        pin = attrs.get('pin')
        
        if phone and pin:
            try:
                # Find user by phone number
                user = User.objects.get(phone=phone)
                
                # Check PIN
                if user.check_pin(pin):
                    if not user.is_active:
                        raise serializers.ValidationError('User account is disabled.')
                    attrs['user'] = user
                    return attrs
                else:
                    raise serializers.ValidationError('Invalid phone number or PIN.')
            except User.DoesNotExist:
                raise serializers.ValidationError('Invalid phone number or PIN.')
        else:
            raise serializers.ValidationError('Must include phone number and PIN.')

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'phone', 'blood_group', 'latitude', 'longitude', 'is_donor'
        ]