from django.urls import path
from .views import RegisterView, NearbyDonorsView, ProfileView, PhoneLoginView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('register/', RegisterView.as_view(), name="register"),
    path('login/', PhoneLoginView.as_view(), name="phone_login"),
    path('token/refresh/', TokenRefreshView.as_view(), name="token_refresh"),
    path('profile/', ProfileView.as_view(), name="profile"),
    path('donors/', NearbyDonorsView.as_view(), name="nearby_donors"),
]
