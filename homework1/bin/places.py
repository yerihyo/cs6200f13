#!/usr/bin/python
'''
This script provides a way to fetch venue information from Google Places.
Run with the --help argument to see your options.
'''

import argparse
import csv
import json
import sys

from urllib import urlencode
from urllib2 import urlopen, URLError

class PlaceGeometry(object):
    ''' The geometry for a place (e.g. coordinates) '''
    
    def __init__(self, location={}, viewport={}):
        if location:
            self.location = (location['lat'], location['lng'])
        else:
            self.location = None


class Place(object):
    ''' A single place from the Places API '''
    
    def __init__(self, id=None, name=None, reference=None, vicinity=None, icon=None, rating=None, opening_hours=None, price_level=None, photos=None, geometry={}, types=[]):
        self.name = name
        self.reference = reference
        self.geometry = PlaceGeometry(**geometry)
        self.vicinity = vicinity
        self.types = types
        self.icon = icon
        self.id = id
        self.rating = rating
        self.opening_hours = opening_hours
        self.price_level = price_level

    def __repr__(self):
        return '(Place: {} at {}, {})'.format(self.name, self.geometry.location[0], self.geometry.location[1])


class Places(object):
    ''' A class for making API requests to Google Places '''

    ROOT_URL = 'https://maps.googleapis.com/maps/api/place/{}/json?{}'

    def __init__(self, key):
        self.key = key

    def nearby(self, latitude, longitude, radius=None, sensor=False, keywords=None, name=None, types=None, ranking='prominence'):
        ''' Run a nearby search '''
        return self._request('nearbysearch',
                             location='{},{}'.format(latitude, longitude),
                             radius=radius,
                             sensor='true' if sensor else 'false',
                             keyword=keywords,
                             name=name,
                             ranking=ranking,
                             type=types,
                             )
        
    def _request(self, request, **kwargs):
        ''' Construct a request URL and make a request of the Google Places API '''

        # Populate the required arguments
        kwargs['key'] = self.key

        # Construct the URL
        for (k, v) in kwargs.items():
            if v is None:
                del kwargs[k]
        url = Places.ROOT_URL.format(request, urlencode(kwargs.items(), True))

        # Fetch the URL
        response = urlopen(url) # May raise URLError
        if response.getcode() != 200:
            raise URLError('Got response code {} for {} request'.format(response.getcode(), request))

        # Read the content
        response_obj = json.loads(response.read())
        if response_obj['status'] != u'OK':
            raise URLError('Request was rejected: {}'.format(request))
        return [Place(**r) for r in response_obj['results']]

class PlacesScript(object):

    ''' A class to implement the command line interface '''
    def __init__(self, args, key=None):
        self.args = args
        self.places = None

    def run(self):

        # Set up the object to interact with the API
        key = self.args.key.readline().rstrip()
        self.places = Places(key=key)

        # Run the requested function
        self.args.func(self)

    def run_nearby(self):
        response = self.places.nearby(latitude=self.args.latitude,
                                      longitude=self.args.longitude,
                                      radius=self.args.radius,
                                      keywords=self.args.keyword,
                                      name=self.args.name,
                                      ranking='distance' if self.args.by_distance else 'prominence',
                                      types=self.args.type,
                                      )
        if self.args.csv:
            types = set()
            for p in response:
                types |= set(p.types)
            types = list(types)
            w = csv.writer(sys.stdout)
            w.writerow(['id', 'name', 'vicinity', 'rating', 'price_level'] + map(lambda x : 'is_' + x, types))
            for p in response:
                row = [p.id, p.name, p.vicinity, p.rating, p.price_level]
                for t in types:
                    row.append(1 if t in p.types else 0)
                w.writerow(row)
        else:
            print response
    

# Run the command-line interface
if __name__ == '__main__':
    cli = argparse.ArgumentParser()
    cli.add_argument('--key', '-k', type=argparse.FileType('r'), required=True, help='The path to a file containing a Google Places API key')
    commands = cli.add_subparsers(help='Available commands')

    nearby = commands.add_parser('nearby', help='Search for places near a location')
    nearby.add_argument('latitude', type=float, help='The latitude of the location to search')
    nearby.add_argument('longitude', type=float, help='The longitude of the location to search')
    nearby.add_argument('--radius', '-r', type=float, help='The search radius, in meters')
    nearby.add_argument('--keyword', '-k', action='append', help='A keyword to search for (repeat as desired)')
    nearby.add_argument('--name', '-n', action='append', help='A term to find in the name (repeat as desired)')
    nearby.add_argument('--type', '-t', action='append', help='The type of place you want (repeat as desired)')
    nearby.add_argument('--by_distance', '-d', action='store_true', help='Rank by distance, rather than prominence; can\'t be used with -r')
    nearby.add_argument('--csv', action='store_true', help='Output as CSV')
    nearby.set_defaults(func=PlacesScript.run_nearby)


    # Parse the command line and run the appropriate command
    args = cli.parse_args()
    PlacesScript(args).run()
