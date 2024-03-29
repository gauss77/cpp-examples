// acquireRelease.cpp

#include <atomic>
#include <iostream>
#include <string>
#include <thread>

using namespace std;

atomic<string*> ptr;
int intData;
atomic<int> atoData;

void producer() {
  string* p = new string("C++11");
  intData = 2011;
  atoData.store(2014, memory_order_relaxed);
  ptr.store(p, memory_order_release);
}

void consumer() {
  string* p2;
  while (!(p2 = ptr.load(memory_order_acquire)));
  cout << "*p2: " << *p2 << endl;
  cout << "data: " << intData << endl;
  cout << "atoData: " << atoData.load(memory_order_relaxed) << endl;
}

int main() {
  cout << endl;

  thread t1(producer);
  thread t2(consumer);

  t1.join();
  t2.join();

  cout << endl;

  return 0;
}
