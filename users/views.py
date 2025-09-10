from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth import get_user_model
from geopy.distance import geodesic
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils import timezone
from django.core.cache import cache
from .serializers import RegisterSerializer, UserSerializer, PhoneLoginSerializer
import logging

User = get_user_model()
logger = logging.getLogger(__name__)

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

class PhoneLoginView(APIView):
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        phone = request.data.get('phone')
        
        # Rate limiting for security
        if phone:
            cache_key = f"login_attempts_{phone}"
            attempts = cache.get(cache_key, 0)
            
            # Block if too many attempts (5 attempts per hour)
            if attempts >= 5:
                return Response({
                    'success': False,
                    'message': 'Too many login attempts. Please try again later.',
                    'data': {'error': 'Account temporarily locked due to multiple failed attempts'}
                }, status=status.HTTP_429_TOO_MANY_REQUESTS)
        
        serializer = PhoneLoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            refresh = RefreshToken.for_user(user)
            
            # Clear failed attempts on successful login
            if phone:
                cache.delete(f"login_attempts_{phone}")
            
            # Log successful login
            logger.info(f"Successful PIN login for phone: {phone}")
            
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }, status=status.HTTP_200_OK)
        
        # Increment failed attempts
        if phone:
            cache_key = f"login_attempts_{phone}"
            attempts = cache.get(cache_key, 0) + 1
            cache.set(cache_key, attempts, 3600)  # Cache for 1 hour
            
            # Log failed attempt
            logger.warning(f"Failed PIN login attempt for phone: {phone} (Attempt {attempts}/5)")
        
        return Response({
            'success': False,
            'message': 'Login failed',
            'data': {'error': 'Invalid phone number or PIN'}
        }, status=status.HTTP_400_BAD_REQUEST)

class ProfileView(generics.RetrieveAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

class NearbyDonorsView(generics.GenericAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]  # Added authentication requirement

    def get(self, request):
        blood_group = request.query_params.get("blood_group")
        latitude = request.query_params.get("latitude")
        longitude = request.query_params.get("longitude")
        radius = float(request.query_params.get("radius", 10))  # Default 10 km
        
        # Validate inputs
        if not blood_group or not latitude or not longitude:
            return Response({
                "success": False,
                "error": "blood_group, latitude, and longitude are required"
            }, status=400)

        try:
            latitude = float(latitude)
            longitude = float(longitude)
        except ValueError:
            return Response({
                "success": False,
                "error": "Invalid latitude or longitude format"
            }, status=400)

        donors = User.objects.filter(is_donor=True, blood_group=blood_group)
        nearby = []

        for donor in donors:
            if donor.latitude and donor.longitude:
                distance = geodesic((latitude, longitude), (donor.latitude, donor.longitude)).km
                if distance <= radius:  # Only include donors within radius
                    data = UserSerializer(donor).data
                    data['distance_km'] = round(distance, 2)
                    nearby.append(data)

        # Sort by distance
        nearby.sort(key=lambda x: x['distance_km'])

        return Response({
            "success": True,
            "donors": nearby,
            "total_found": len(nearby)
        })